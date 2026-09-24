
"""
wyz2vtii.py - Convierte proyectos WYZTracker (.wyz, XML+gzip) a modulos de
texto de Vortex Tracker II (.txt), que luego se compilan a .pt3 en Vortex.
(NOTA:El resultado es solo una aproximacion al sonido original)
(C) copyleft 2026 salvaKantero

Uso:
    python wyz2vtii.py <fichero.wyz> [salida.txt]
    python wyz2vtii.py --all <carpeta_WYZ>   # convierte todos los .wyz

Mapeo principal:
  - Notas WYZ (letras ASCII A-G, Seminote 43='#', octava 1:1) -> "C-4","A#5".
    Note==80 ('P') -> note-off ("R--"). Vacio -> "---".
  - Instrumentos melodicos -> Samples Vortex 1..N (Volumes=vol, PitchModifiers=tono).
  - Effects (KICK/SNARE/hat) -> Samples de ruido, disparados a nota fija en canal B.
  - PlayOrder + LoopToPattern -> PlayOrder con marca "L".
  - Tempo -> Speed. EnvData se ignora (ActiveFrequencies siempre false).
"""
import sys, os, gzip, base64, math
import xml.etree.ElementTree as ET

NULL = -2147483648            # Int32.MinValue = "sin valor" en WYZTracker
NOTE_LETTERS = {65:'A',66:'B',67:'C',68:'D',69:'E',70:'F',71:'G'}
NOTEOFF = 80                  # 'P'
B32 = '0123456789ABCDEFGHIJKLMNOPQRSTUV'   # columna de sample/ornamento Vortex

# --- parametros ajustables (calibrar de oido) ---
OCTAVE_OFFSET = 0            # desplazamiento de octava WYZ->Vortex (0 = lo mas cercano de oido)
USE_ORNAMENTS = False        # saltos de octava por tick (bit5/6) como ornamentos Vortex.
                             # DESACTIVADO: la interpretacion actual sonaba peor (signo
                             # invertido / trinos disonantes). Revisar con oido antes de reactivar.
DRUMS_ONLY_FX = False        # si True, el canal de FX lleva SOLO percusion (descarta la
                             # melodia/eco de ese canal). Util cuando B es un eco de C que,
                             # sin el timbre original, suena a destiempo (ej. gameover).
FLAT_VOLUME = 0x0B           # volumen para instrumentos SIN envolvente (tipo Sawtooth, que
                             # de origen usan envolvente HW). A maximo (F) revientan el mix;
                             # se rinden a un nivel moderado para equilibrar.
BASS_BOOST  = 3              # +volumen para instrumentos de bajo (nombre "BASS" u octava-abajo):
                             # los graves/octava-abajo se perciben mas flojos en el AY.
SAWTOOTH_SHIFT = 0           # semitonos a subir los instrumentos SIN envolvente (Sawtooth).
                             # Probado +12 (octava): se pasaba de agudo (lo "mas grave" del
                             # original es TIMBRE de la envolvente HW, no tono) -> 0 = sin shift.
TRILL_SHIFT = -12            # los instrumentos con TRINO de octava (nota<->+1oct) se perciben
                             # en la octava de abajo; como el trino no se reproduce, se aplanan
                             # esa octava abajo para que cuadre el tono con el original.
DRUM_CHANNEL  = None         # se lee de FxChannel; canal donde van los drums
DRUM_NOTE     = 'C-4'        # nota fija para disparar percusion
AY_CLOCK      = 1773400      # reloj AY del Spectrum (de ChipFrequency)
NOTE_TABLE    = 2            # tabla de notas Vortex

# periodo AY del DRUM_NOTE (para convertir frecuencias absolutas a offsets)
def note_period(name):
    letter = name[0]; acc = name[1]; octave = int(name[2])
    semis = {'C':0,'D':2,'E':4,'F':5,'G':7,'A':9,'B':11}[letter]
    if acc == '#': semis += 1
    # MIDI-ish: C-0 = 0; freq con A4=440 (octava 4)
    n = semis + 12*octave
    a4 = 9 + 12*4
    freq = 440.0 * (2.0 ** ((n - a4)/12.0))
    return int(round(AY_CLOCK / (16.0 * freq)))

DRUM_BASE_PERIOD = note_period(DRUM_NOTE)


def b64bytes(s):
    if s is None or s.strip() == '': return []
    return list(base64.b64decode(s.strip()))


def txt(el, tag, default=None):
    c = el.find(tag)
    return c.text if c is not None and c.text is not None else default


# ---------------------------------------------------------------------------
# Carga del WYZ
# ---------------------------------------------------------------------------
def load_wyz(path):
    with gzip.open(path, 'rb') as f:
        data = f.read()
    return ET.fromstring(data)


def parse_instruments(root):
    """Lista de dicts: {name, vols[], pitch[], looped, loopstart}."""
    out = []
    cont = root.find('Instruments')
    if cont is None: return out
    for ins in cont.findall('Instrument'):
        vols = b64bytes(txt(ins, 'Volumes'))
        pm = ins.find('PitchModifiers')
        pitch = [int(i.text) for i in pm.findall('int')] if pm is not None else []
        out.append({
            'id': txt(ins, 'ID', ''),
            'name': txt(ins, 'Name', ''),
            'vols': vols,
            'pitch': pitch,
            'looped': (txt(ins, 'Looped', 'false') == 'true'),
            'loopstart': int(txt(ins, 'LoopStart', '0')),
        })
    return out


def parse_effects(root):
    """Lista de dicts de percusion: {name, vols[], noises[], freqs[]}."""
    out = []
    cont = root.find('Effects')
    if cont is None: return out
    for ef in cont.findall('Effect'):
        fr = ef.find('Frequencies')
        freqs = [int(i.text) for i in fr.findall('int')] if fr is not None else []
        out.append({
            'id': txt(ef, 'ID', ''),
            'name': txt(ef, 'Name', ''),
            'vols': b64bytes(txt(ef, 'Volumes')),
            'noises': b64bytes(txt(ef, 'Noises')),
            'freqs': freqs,
        })
    return out


def parse_patterns(root):
    """Lista de patrones; cada patron = lista de filas.
    Fila = (notes[3], fx) donde note = (octave, note, seminote, instrument) o None."""
    pats = []
    cont = root.find('Patterns')
    for pat in cont.findall('Pattern'):
        rows = []
        for cl in pat.find('Lines').findall('ChannelLine'):
            notes = []
            for cn in cl.find('Notes').findall('ChannelNote'):
                octave = int(txt(cn, 'Octave', str(NULL)))
                note   = int(txt(cn, 'Note', '0'))
                semi   = int(txt(cn, 'Seminote', '0'))
                instr  = txt(cn, 'Instrument', '')   # ID (puede ser letra)
                if octave == NULL and note == 0:
                    notes.append(None)
                else:
                    notes.append((octave, note, semi, instr))
            fxv = txt(cl, 'Fx', str(NULL))
            fx = int(fxv)
            rows.append((notes, fx if fx != NULL else None))
        pats.append(rows)
    return pats


# ---------------------------------------------------------------------------
# Conversion de notas
# ---------------------------------------------------------------------------
def vortex_note(octave, note, semi):
    if note == NOTEOFF:
        return 'R--'
    if note not in NOTE_LETTERS or octave == NULL:
        return '---'
    letter = NOTE_LETTERS[note]
    acc = '#' if semi == 43 else '-'
    return '%s%s%d' % (letter, acc, octave + OCTAVE_OFFSET)


def sample_char(n):
    return B32[n] if 0 <= n < len(B32) else '0'


# ---------------------------------------------------------------------------
# Generacion de samples Vortex
# ---------------------------------------------------------------------------
def fmt_sample_line(tone_on, noise_on, env_on, tone_off, noise_off, vol, loop):
    t = 'T' if tone_on else 't'
    n = 'N' if noise_on else 'n'
    e = 'E' if env_on else 'e'
    sign = '+' if tone_off >= 0 else '-'
    line = '%s%s%s %s%03X_ +%02X_ %X_' % (t, n, e, sign, abs(tone_off) & 0xFFF,
                                          noise_off & 0xFF, vol & 0xF)
    if loop: line += ' L'
    return line


# Formato del byte de Volumes (PAUTA del instrumento), segun WYZPlayer:
#   bits 0-3 = volumen (0-15)
#   bit 4 (0x10) = modo del PitchModifier: 1=semitonos (ornamento), 0=slide de frecuencia
#   bit 5 (0x20) = subir una octava (+12 semitonos) este tick
#   bit 6 (0x40) = bajar una octava (-12 semitonos) este tick
def is_bass(ins):
    """Bajo = nombre contiene BASS, o el instrumento tiene octava-abajo neta (FX...)."""
    if 'BASS' in (ins['name'] or '').upper():
        return True
    cum = 0; seq = []
    for b in ins['vols']:
        if b & 0x40: cum += 12
        if b & 0x20: cum -= 12
        seq.append(cum)
    if not seq:
        return False
    ls = ins['loopstart']
    region = seq[ls:] if (ins['looped'] and ls < len(seq)) else [seq[-1]]
    return len(set(region)) == 1 and region[0] < 0


def instrument_to_sample(ins):
    vols = ins['vols']; pitch = ins['pitch']
    if not vols:
        return ['Tne +000_ +00_ %X_ L' % FLAT_VOLUME]   # sin envolvente -> tono plano moderado
    boost = BASS_BOOST if is_bass(ins) else 0
    n = max(len(vols), len(pitch))
    # sin loop -> el player WYZ mantiene el ultimo valor (sostiene), no enmudece:
    # se hace loop sobre la ultima linea.
    loopidx = ins['loopstart'] if ins['looped'] else (n - 1)
    lines = []
    for i in range(n):
        b = vols[i] if i < len(vols) else vols[-1]
        v = min(15, (b & 0x0F) + boost)          # nibble bajo = volumen (+ boost si es bajo)
        # el pitch va al sample; con ornamentos activos, en modo semitono (bit4=1)
        # va al ornamento en su lugar.
        p = pitch[i] if i < len(pitch) else 0
        if USE_ORNAMENTS and (b & 0x10):
            p = 0
        lines.append(fmt_sample_line(True, False, False, p, 0, v, i == loopidx))
    return lines


def instrument_to_ornament(ins):
    """Ornamento Vortex (transposicion en semitonos por tick) a partir de los
    saltos de octava (bits 5/6) y los PitchModifiers en modo semitono (bit4).
    Devuelve (lineas[], loopidx) o None si no hay movimiento."""
    vols = ins['vols']; pitch = ins['pitch']
    if not vols:
        return None
    n = max(len(vols), len(pitch))
    offs = []; cum = 0
    for i in range(n):
        b = vols[i] if i < len(vols) else vols[-1]
        # ACUMULATIVO sobre la frecuencia viva (como el player: lee/modifica/escribe
        # el registro, no reinicia a la nota base). bit6=periodo/2=+1oct;
        # bit5=periodo*2=-1oct.
        if b & 0x40:
            cum += 12
        if b & 0x20:
            cum -= 12
        o = cum
        if b & 0x10:                             # modo semitonos -> al ornamento
            o += pitch[i] if i < len(pitch) else 0
        offs.append(o)
    if not any(offs):
        return None
    looped = ins['looped']
    loopidx = ins['loopstart'] if looped else n  # no loop -> loop en el 0 final
    lines = [('L' if i == loopidx else '') + str(o) for i, o in enumerate(offs)]
    if not looped:
        lines.append('L0')
    return lines, loopidx


def instrument_octave_const(ins):
    """Ornamento SOLO para desplazamiento de octava CONSTANTE (transposicion pura,
    p.ej. bajos FX a -12 o leads a +12). Devuelve (lineas, loopidx) o None.
    NO genera trinos (octava que oscila) -> esos sonaban mal y se descartan; ni
    blips de ataque que vuelven a 0 (octava neta nula)."""
    vols = ins['vols']
    if not vols:
        return None
    cum = 0; seq = []
    for b in vols:
        if b & 0x40:
            cum += 12        # bit6 = +1 octava
        if b & 0x20:
            cum -= 12        # bit5 = -1 octava
        seq.append(cum)
    # un TRINO oscila (varios cambios de valor); un blip de ataque cambia 1 vez
    transitions = sum(1 for i in range(1, len(seq)) if seq[i] != seq[i - 1])
    if transitions >= 2:
        shift = TRILL_SHIFT          # TRINO -> se percibe 1 oct abajo (aplanar ahi)
    else:
        looped = ins['looped']; ls = ins['loopstart']
        region = seq[ls:] if (looped and ls < len(seq)) else [seq[-1]]
        shift = region[0] if len(set(region)) == 1 else 0   # octava CONSTANTE sostenida
    if shift == 0:
        return None
    return (['L%d' % shift], 0)      # ornamento constante de transposicion


def effect_to_sample(ef):
    vols = ef['vols']; noises = ef['noises']; freqs = ef['freqs']
    n = max(len(vols), len(noises), len(freqs))
    if n == 0:
        return ['tne +000_ +00_ 0_ L']
    lines = []
    for i in range(n):
        v = (vols[i] if i < len(vols) else 0) & 0x0F
        nz = noises[i] if i < len(noises) else 0
        fr = freqs[i] if i < len(freqs) else 0
        tone_on = fr > 0
        noise_on = nz > 0
        toff = (fr - DRUM_BASE_PERIOD) if tone_on else 0
        lines.append(fmt_sample_line(tone_on, noise_on, False, toff, nz, v, False))
    lines.append('tne +000_ +00_ 0_ L')          # cola de silencio
    return lines


# ---------------------------------------------------------------------------
# Validacion / red de seguridad
# ---------------------------------------------------------------------------
def validate(instruments, effects, patterns, play, inst_sample, eff_sample):
    """Devuelve (warnings[], stats_line). Solo revisa los patrones que se
    reproducen realmente (los referenciados por el PlayOrder)."""
    warn = []
    npat = len(patterns)
    bad = [p for p in play if not (0 <= p < npat)]
    if bad:
        warn.append('PlayOrder referencia patrones inexistentes: %s' % bad)
    used = sorted(set(p for p in play if 0 <= p < npat))
    empty_ids = {ins['id'] for ins in instruments if not ins['vols']}

    unknown_inst, unknown_fx, empty_used = set(), set(), set()
    omin, omax, n_notes, n_drums = 99, -99, 0, 0
    for pidx in used:
        for notes, fx in patterns[pidx]:
            for cn in notes:
                if cn is None:
                    continue
                o, n, s, instr = cn
                if n == NOTEOFF or n not in NOTE_LETTERS or o == NULL:
                    continue
                n_notes += 1
                oo = o + OCTAVE_OFFSET
                omin, omax = min(omin, oo), max(omax, oo)
                if instr and instr not in inst_sample:
                    unknown_inst.add(instr)
                elif instr in empty_ids:
                    empty_used.add(instr)
            if fx is not None:
                n_drums += 1
                if str(fx) not in eff_sample:
                    unknown_fx.add(fx)

    if unknown_inst:
        warn.append('notas con instrumento desconocido (se mantiene el actual): %s'
                    % sorted(unknown_inst))
    if unknown_fx:
        warn.append('FX que referencian un Effect inexistente (golpe omitido): %s'
                    % sorted(unknown_fx))
    if empty_used:
        names = sorted('%s(%s)' % (i, next((x['name'] for x in instruments
                       if x['id'] == i), '?')) for i in empty_used)
        warn.append('instrumentos sin envolvente usados (tono plano vol. max): %s' % names)
    if n_notes and (omin < 1 or omax > 8):
        warn.append('octavas fuera del rango Vortex 1..8: min=%d max=%d' % (omin, omax))

    stats = ('patrones usados=%d/%d  notas=%d  golpes FX=%d  octavas=%d..%d'
             % (len(used), npat, n_notes, n_drums,
                omin if n_notes else 0, omax if n_notes else 0))
    return warn, stats


# ---------------------------------------------------------------------------
# Generacion del modulo de texto
# ---------------------------------------------------------------------------
def build_module(root, title):
    global DRUM_CHANNEL
    instruments = parse_instruments(root)
    effects     = parse_effects(root)
    patterns    = parse_patterns(root)
    tempo       = int(txt(root, 'Tempo', '6'))
    DRUM_CHANNEL = int(txt(root, 'FxChannel', '1'))

    play = [int(i.text) for i in root.find('PlayOrder').findall('int')]
    loopto = int(txt(root, 'LoopToPattern', '0'))

    # se conservan los numeros de patron ORIGINALES de WYZ (para poder comparar
    # patron a patron con WYZTracker). Los patrones no usados dentro del rango se
    # emiten como un placeholder vacio de 1 fila para mantener numeracion contigua.
    used_pats = sorted(set(p for p in play if 0 <= p < len(patterns)))
    max_pat = max(used_pats) if used_pats else -1
    used_set = set(used_pats)

    # asignacion de samples: instrumentos 1..K, effects K+1.. (clave = ID WYZ)
    inst_sample = {ins['id']: i + 1 for i, ins in enumerate(instruments)}
    eff_sample  = {ef['id']: len(instruments) + 1 + i for i, ef in enumerate(effects)}

    # ornamentos (transposicion por tick: octavas bit5/6 + semitonos bit4) con
    # dedup; clave = ID WYZ -> numero de ornamento (0 = ninguno). Max 15 slots.
    orn_defs, orn_keys, inst_orn = [], [], {}
    for ins in instruments:
        if not ins['vols'] and SAWTOOTH_SHIFT:
            # instrumento sin envolvente (Sawtooth): su envolvente HW suena +1 oct
            res = (['L%d' % SAWTOOTH_SHIFT], 0)
        else:
            # trinos de octava (USE_ORNAMENTS, off) o transposicion de octava constante
            res = instrument_to_ornament(ins) if USE_ORNAMENTS else instrument_octave_const(ins)
        if res is None:
            inst_orn[ins['id']] = 0
        elif tuple(res[0]) in orn_keys:
            inst_orn[ins['id']] = orn_keys.index(tuple(res[0])) + 1
        elif len(orn_defs) < 15:
            orn_defs.append(res); orn_keys.append(tuple(res[0]))
            inst_orn[ins['id']] = len(orn_defs)
        else:
            inst_orn[ins['id']] = 0          # sin slots libres -> sin ornamento

    out = []
    # --- cabecera ---
    out.append('[Module]')
    out.append('VortexTrackerII=0')
    out.append('Version=3.7')
    out.append('Title=%s' % title)
    out.append('Author=')
    out.append('NoteTable=%d' % NOTE_TABLE)
    out.append('Speed=%d' % tempo)
    porder = []
    for idx, p in enumerate(play):
        porder.append(('L' if idx == loopto else '') + str(p))   # numeros originales
    out.append('PlayOrder=' + ','.join(porder))
    out.append('')

    # --- ornamentos ---
    for k in range(1, 16):
        out.append('[Ornament%d]' % k)
        out.extend(orn_defs[k - 1][0] if k <= len(orn_defs) else ['L0'])
        out.append('')

    # --- samples ---
    samples = {}
    for i, ins in enumerate(instruments):
        samples[i + 1] = instrument_to_sample(ins)
    for i, ef in enumerate(effects):
        samples[len(instruments) + 1 + i] = effect_to_sample(ef)
    for k in range(1, 32):
        out.append('[Sample%d]' % k)
        out.extend(samples.get(k, ['tne +000_ +00_ 0_ L']))
        out.append('')

    # --- patrones (numeros originales de WYZ; huecos = placeholder vacio) ---
    for pidx in range(max_pat + 1):
        out.append('[Pattern%d]' % pidx)
        if pidx not in used_set:
            out.append('....|..|--- .... ....|--- .... ....|--- .... ....')
            out.append('')
            continue
        rows = patterns[pidx]
        bcur = ('1', '0') # (sample, ornamento) "actual" del canal de FX (nunca '.')
        cur_note = None   # nota melodica "viva" en B (ns, sc, oc); None tras R--
        replay = False    # hay que re-afirmar cur_note en el proximo hueco
        for notes, fx in rows:
            chans = []
            for ch in range(3):
                cn = notes[ch] if ch < len(notes) else None

                # ---------- canal de percusion (FX): 4 voces -> 3 canales ----------
                # Conserva TODOS los golpes. Si una nota de B coincide con un golpe,
                # gana el golpe y la nota se aplaza UNA vez al hueco siguiente (para
                # no perderla). NO se reanudan notas interrumpidas por golpes sueltos:
                # WYZ tampoco lo hace y reanudarlas generaba notas fantasma.
                if ch == DRUM_CHANNEL:
                    # modo "solo percusion": se descarta la melodia/eco del canal
                    if DRUMS_ONLY_FX:
                        if fx is not None and str(fx) in eff_sample:
                            chans.append('%s %s.0F ....'
                                         % (DRUM_NOTE, sample_char(eff_sample[str(fx)])))
                        else:
                            chans.append('--- .... ....')
                        continue
                    ns = '---'; expl_sc = None; expl_oc = None
                    if cn is not None:
                        ns = vortex_note(cn[0], cn[1], cn[2])
                        if ns not in ('---', 'R--'):
                            sn = inst_sample.get(cn[3])
                            if sn:
                                expl_sc = sample_char(sn)
                                expl_oc = B32[inst_orn.get(cn[3], 0)]
                    noteon = ns not in ('---', 'R--')
                    drum = fx is not None and str(fx) in eff_sample
                    dc = sample_char(eff_sample[str(fx)]) if drum else None
                    if noteon:
                        sc = expl_sc if expl_sc else bcur[0]   # nunca '.' (sonaria a drum)
                        oc = expl_oc if expl_sc else bcur[1]
                        if expl_sc:
                            bcur = (expl_sc, expl_oc)
                        cur_note = (ns, sc, oc)
                        if drum:                           # se conserva el golpe...
                            chans.append('%s %s.0F ....' % (DRUM_NOTE, dc))
                            replay = True                  # ...y la nota se re-afirma en el hueco
                        else:
                            chans.append('%s %s.%sF ....' % (ns, sc, oc))
                            replay = False
                    elif drum:
                        # el golpe pisa lo que hubiera; NO se reanuda la nota (WYZ
                        # tampoco la reanuda -> reanudarla generaba notas fantasma)
                        chans.append('%s %s.0F ....' % (DRUM_NOTE, dc))
                    elif ns == 'R--':
                        chans.append('R-- .... ....'); cur_note = None; replay = False
                    elif replay and cur_note:
                        rns, rsc, roc = cur_note; replay = False
                        chans.append('%s %s.%sF ....' % (rns, rsc, roc))
                    else:
                        chans.append('--- .... ....')
                    continue

                # ---------- canales melodicos (A / C) ----------
                if cn is None:
                    chans.append('--- .... ....')
                else:
                    octave, note, semi, instr = cn
                    ns = vortex_note(octave, note, semi)
                    if ns in ('---', 'R--'):
                        chans.append('%s .... ....' % ns)
                    else:
                        sn = inst_sample.get(instr)
                        if sn:
                            sc = sample_char(sn); oc = B32[inst_orn.get(instr, 0)]
                            chans.append('%s %s.%sF ....' % (ns, sc, oc))
                        else:  # instrumento vacio/desconocido -> mantener actual
                            chans.append('%s ...F ....' % ns)
            out.append('....|..|' + '|'.join(chans))
        out.append('')

    report = validate(instruments, effects, patterns, play, inst_sample, eff_sample)
    return '\n'.join(out) + '\n', report


def convert(path, outpath=None):
    root = load_wyz(path)
    base = os.path.splitext(os.path.basename(path))[0]
    title = txt(root, 'Name', base) or base
    text, (warnings, stats) = build_module(root, title)
    if outpath is None:
        outpath = os.path.splitext(path)[0] + '.txt'
    with open(outpath, 'w', encoding='utf-8', newline='\r\n') as f:
        f.write(text)
    print('OK: %s -> %s' % (os.path.basename(path), os.path.basename(outpath)))
    print('    %s' % stats)
    for w in warnings:
        print('    [!] %s' % w)
    return outpath


def main(argv):
    global DRUMS_ONLY_FX
    args = [a for a in argv[1:] if a != '--drums-only']
    if '--drums-only' in argv:           # canal de FX = solo percusion (sin eco)
        DRUMS_ONLY_FX = True
    if not args:
        print(__doc__); return 1
    if args[0] == '--all':
        folder = args[1]
        for fn in sorted(os.listdir(folder)):
            if fn.lower().endswith('.wyz'):
                convert(os.path.join(folder, fn))
        return 0
    convert(args[0], args[1] if len(args) > 1 else None)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))