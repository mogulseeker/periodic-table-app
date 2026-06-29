import SwiftUI
import AppKit

// MARK: - Model

enum Category: String {
    case alkali, alkaline, transition, postt, metalloid, nonmetal, halogen, noble, lanth, actin, unknown

    var display: String {
        switch self {
        case .alkali: return "Alkali metal"
        case .alkaline: return "Alkaline earth metal"
        case .transition: return "Transition metal"
        case .postt: return "Post-transition metal"
        case .metalloid: return "Metalloid"
        case .nonmetal: return "Reactive nonmetal"
        case .halogen: return "Halogen"
        case .noble: return "Noble gas"
        case .lanth: return "Lanthanide"
        case .actin: return "Actinide"
        case .unknown: return "Unknown / predicted"
        }
    }

    var color: Color {
        switch self {
        case .alkali:     return Color(red: 0.93, green: 0.33, blue: 0.31)
        case .alkaline:   return Color(red: 0.95, green: 0.55, blue: 0.27)
        case .transition: return Color(red: 0.96, green: 0.78, blue: 0.30)
        case .postt:      return Color(red: 0.40, green: 0.73, blue: 0.55)
        case .metalloid:  return Color(red: 0.30, green: 0.70, blue: 0.67)
        case .nonmetal:   return Color(red: 0.35, green: 0.60, blue: 0.85)
        case .halogen:    return Color(red: 0.34, green: 0.78, blue: 0.86)
        case .noble:      return Color(red: 0.65, green: 0.49, blue: 0.86)
        case .lanth:      return Color(red: 0.90, green: 0.45, blue: 0.70)
        case .actin:      return Color(red: 0.78, green: 0.40, blue: 0.78)
        case .unknown:    return Color(red: 0.55, green: 0.57, blue: 0.60)
        }
    }
}

enum PhysState: String {
    case s, l, g, u
    var display: String {
        switch self {
        case .s: return "Solid"
        case .l: return "Liquid"
        case .g: return "Gas"
        case .u: return "Unknown"
        }
    }
    var glyph: String {
        switch self {
        case .s: return "▪︎ solid"
        case .l: return "💧 liquid"
        case .g: return "☁︎ gas"
        case .u: return "? unknown"
        }
    }
}

struct Element: Identifiable {
    let z: Int
    let sym: String
    let name: String
    let mass: Double
    let cat: Category
    let state: PhysState
    let block: String          // s, p, d, f
    let group: Int?
    let period: Int
    let econf: String
    let ox: String             // oxidation states / charges, e.g. "+2,+3"
    let en: Double?
    let melt: Double?          // K
    let boil: Double?          // K
    let density: Double?       // g/cm^3

    var id: Int { z }

    // Mass number A (most common / most stable isotope, rounded)
    var massNumber: Int { Int(mass.rounded()) }

    // Subatomic particle counts for the neutral atom.
    var protons: Int { z }
    var electrons: Int { z }
    var neutrons: Int { massNumber - z }

    // Full electron configuration, expanding any [NobleGas] core to its 1s… form.
    var fullEconf: String {
        func expand(_ cfg: String) -> String {
            guard cfg.hasPrefix("["), let close = cfg.firstIndex(of: "]") else { return cfg }
            let sym = String(cfg[cfg.index(after: cfg.startIndex)..<close])
            let rest = cfg[cfg.index(after: close)...].trimmingCharacters(in: .whitespaces)
            guard let core = ELEMENTS.first(where: { $0.sym == sym }) else { return cfg }
            return (expand(core.econf) + " " + rest).trimmingCharacters(in: .whitespaces)
        }
        return expand(econf)
    }

    // The differentiating (filling) subshell label, e.g. "1s", "2p", "3d", "4f"
    var subshell: String {
        switch block {
        case "s": return "\(period)s"
        case "p": return "\(period)p"
        case "d": return "\(period - 1)d"
        case "f": return "\(period - 2)f"
        default:  return ""
        }
    }

    // Grid position (row, col) in the 18-wide layout. f-block sits in rows 9 & 10.
    var pos: (row: Int, col: Int) {
        if (57...71).contains(z) { return (9, 3 + (z - 57)) }
        if (89...103).contains(z) { return (10, 3 + (z - 89)) }
        return (period, group ?? 3)
    }
}

// MARK: - Data (all 118 elements)
// Fields: z;sym;name;mass;cat;state;block;group;period;econf;ox;en;melt(K);boil(K);density(g/cm3)

let RAW_DATA = """
1;H;Hydrogen;1.008;nonmetal;g;s;1;1;1s1;+1,-1;2.20;13.99;20.27;
2;He;Helium;4.0026;noble;g;s;18;1;1s2;0;;;4.22;
3;Li;Lithium;6.94;alkali;s;s;1;2;[He]2s1;+1;0.98;453.65;1603;0.534
4;Be;Beryllium;9.0122;alkaline;s;s;2;2;[He]2s2;+2;1.57;1560;2742;1.85
5;B;Boron;10.81;metalloid;s;p;13;2;[He]2s2 2p1;+3;2.04;2349;4200;2.34
6;C;Carbon;12.011;nonmetal;s;p;14;2;[He]2s2 2p2;+4,-4;2.55;3823;4098;2.27
7;N;Nitrogen;14.007;nonmetal;g;p;15;2;[He]2s2 2p3;-3,+5;3.04;63.15;77.36;
8;O;Oxygen;15.999;nonmetal;g;p;16;2;[He]2s2 2p4;-2;3.44;54.36;90.20;
9;F;Fluorine;18.998;halogen;g;p;17;2;[He]2s2 2p5;-1;3.98;53.48;85.03;
10;Ne;Neon;20.180;noble;g;p;18;2;[He]2s2 2p6;0;;24.56;27.07;
11;Na;Sodium;22.990;alkali;s;s;1;3;[Ne]3s1;+1;0.93;370.95;1156;0.971
12;Mg;Magnesium;24.305;alkaline;s;s;2;3;[Ne]3s2;+2;1.31;923;1363;1.738
13;Al;Aluminium;26.982;postt;s;p;13;3;[Ne]3s2 3p1;+3;1.61;933.47;2792;2.70
14;Si;Silicon;28.085;metalloid;s;p;14;3;[Ne]3s2 3p2;+4,-4;1.90;1687;3538;2.329
15;P;Phosphorus;30.974;nonmetal;s;p;15;3;[Ne]3s2 3p3;-3,+3,+5;2.19;317.30;553.65;1.823
16;S;Sulfur;32.06;nonmetal;s;p;16;3;[Ne]3s2 3p4;-2,+4,+6;2.58;388.36;717.87;2.07
17;Cl;Chlorine;35.45;halogen;g;p;17;3;[Ne]3s2 3p5;-1,+1,+5,+7;3.16;171.65;239.11;
18;Ar;Argon;39.95;noble;g;p;18;3;[Ne]3s2 3p6;0;;83.80;87.30;
19;K;Potassium;39.098;alkali;s;s;1;4;[Ar]4s1;+1;0.82;336.53;1032;0.862
20;Ca;Calcium;40.078;alkaline;s;s;2;4;[Ar]4s2;+2;1.00;1115;1757;1.54
21;Sc;Scandium;44.956;transition;s;d;3;4;[Ar]3d1 4s2;+3;1.36;1814;3109;2.99
22;Ti;Titanium;47.867;transition;s;d;4;4;[Ar]3d2 4s2;+4,+3,+2;1.54;1941;3560;4.506
23;V;Vanadium;50.942;transition;s;d;5;4;[Ar]3d3 4s2;+5,+4,+3,+2;1.63;2183;3680;6.11
24;Cr;Chromium;51.996;transition;s;d;6;4;[Ar]3d5 4s1;+6,+3,+2;1.66;2180;2944;7.15
25;Mn;Manganese;54.938;transition;s;d;7;4;[Ar]3d5 4s2;+7,+4,+2;1.55;1519;2334;7.21
26;Fe;Iron;55.845;transition;s;d;8;4;[Ar]3d6 4s2;+3,+2;1.83;1811;3134;7.874
27;Co;Cobalt;58.933;transition;s;d;9;4;[Ar]3d7 4s2;+3,+2;1.88;1768;3200;8.90
28;Ni;Nickel;58.693;transition;s;d;10;4;[Ar]3d8 4s2;+2,+3;1.91;1728;3186;8.908
29;Cu;Copper;63.546;transition;s;d;11;4;[Ar]3d10 4s1;+2,+1;1.90;1357.77;2835;8.96
30;Zn;Zinc;65.38;transition;s;d;12;4;[Ar]3d10 4s2;+2;1.65;692.68;1180;7.14
31;Ga;Gallium;69.723;postt;s;p;13;4;[Ar]3d10 4s2 4p1;+3;1.81;302.91;2673;5.91
32;Ge;Germanium;72.630;metalloid;s;p;14;4;[Ar]3d10 4s2 4p2;+4,+2;2.01;1211.40;3106;5.323
33;As;Arsenic;74.922;metalloid;s;p;15;4;[Ar]3d10 4s2 4p3;-3,+3,+5;2.18;1090;887;5.727
34;Se;Selenium;78.971;nonmetal;s;p;16;4;[Ar]3d10 4s2 4p4;-2,+4,+6;2.55;494;958;4.81
35;Br;Bromine;79.904;halogen;l;p;17;4;[Ar]3d10 4s2 4p5;-1,+1,+5;2.96;265.8;332.0;3.122
36;Kr;Krypton;83.798;noble;g;p;18;4;[Ar]3d10 4s2 4p6;0;3.00;115.79;119.93;
37;Rb;Rubidium;85.468;alkali;s;s;1;5;[Kr]5s1;+1;0.82;312.46;961;1.532
38;Sr;Strontium;87.62;alkaline;s;s;2;5;[Kr]5s2;+2;0.95;1050;1655;2.64
39;Y;Yttrium;88.906;transition;s;d;3;5;[Kr]4d1 5s2;+3;1.22;1799;3609;4.472
40;Zr;Zirconium;91.224;transition;s;d;4;5;[Kr]4d2 5s2;+4;1.33;2128;4682;6.52
41;Nb;Niobium;92.906;transition;s;d;5;5;[Kr]4d4 5s1;+5,+3;1.6;2750;5017;8.57
42;Mo;Molybdenum;95.95;transition;s;d;6;5;[Kr]4d5 5s1;+6,+4;2.16;2896;4912;10.28
43;Tc;Technetium;98;transition;s;d;7;5;[Kr]4d5 5s2;+7,+4;1.9;2430;4538;11.0
44;Ru;Ruthenium;101.07;transition;s;d;8;5;[Kr]4d7 5s1;+4,+3;2.2;2607;4423;12.45
45;Rh;Rhodium;102.91;transition;s;d;9;5;[Kr]4d8 5s1;+3;2.28;2237;3968;12.41
46;Pd;Palladium;106.42;transition;s;d;10;5;[Kr]4d10;+2,+4;2.20;1828.05;3236;12.023
47;Ag;Silver;107.87;transition;s;d;11;5;[Kr]4d10 5s1;+1;1.93;1234.93;2435;10.49
48;Cd;Cadmium;112.41;transition;s;d;12;5;[Kr]4d10 5s2;+2;1.69;594.22;1040;8.65
49;In;Indium;114.82;postt;s;p;13;5;[Kr]4d10 5s2 5p1;+3;1.78;429.75;2345;7.31
50;Sn;Tin;118.71;postt;s;p;14;5;[Kr]4d10 5s2 5p2;+4,+2;1.96;505.08;2875;7.287
51;Sb;Antimony;121.76;metalloid;s;p;15;5;[Kr]4d10 5s2 5p3;+3,+5,-3;2.05;903.78;1860;6.685
52;Te;Tellurium;127.60;metalloid;s;p;16;5;[Kr]4d10 5s2 5p4;-2,+4,+6;2.1;722.66;1261;6.232
53;I;Iodine;126.90;halogen;s;p;17;5;[Kr]4d10 5s2 5p5;-1,+1,+5,+7;2.66;386.85;457.4;4.93
54;Xe;Xenon;131.29;noble;g;p;18;5;[Kr]4d10 5s2 5p6;0,+4,+6;2.6;161.40;165.03;
55;Cs;Caesium;132.91;alkali;s;s;1;6;[Xe]6s1;+1;0.79;301.59;944;1.873
56;Ba;Barium;137.33;alkaline;s;s;2;6;[Xe]6s2;+2;0.89;1000;2170;3.51
57;La;Lanthanum;138.91;lanth;s;d;;6;[Xe]5d1 6s2;+3;1.10;1193;3737;6.162
58;Ce;Cerium;140.12;lanth;s;f;;6;[Xe]4f1 5d1 6s2;+3,+4;1.12;1068;3716;6.770
59;Pr;Praseodymium;140.91;lanth;s;f;;6;[Xe]4f3 6s2;+3;1.13;1208;3793;6.77
60;Nd;Neodymium;144.24;lanth;s;f;;6;[Xe]4f4 6s2;+3;1.14;1297;3347;7.01
61;Pm;Promethium;145;lanth;s;f;;6;[Xe]4f5 6s2;+3;;1315;3273;7.26
62;Sm;Samarium;150.36;lanth;s;f;;6;[Xe]4f6 6s2;+3,+2;1.17;1345;2067;7.52
63;Eu;Europium;151.96;lanth;s;f;;6;[Xe]4f7 6s2;+3,+2;;1099;1802;5.264
64;Gd;Gadolinium;157.25;lanth;s;f;;6;[Xe]4f7 5d1 6s2;+3;1.20;1585;3546;7.90
65;Tb;Terbium;158.93;lanth;s;f;;6;[Xe]4f9 6s2;+3;;1629;3503;8.23
66;Dy;Dysprosium;162.50;lanth;s;f;;6;[Xe]4f10 6s2;+3;1.22;1680;2840;8.540
67;Ho;Holmium;164.93;lanth;s;f;;6;[Xe]4f11 6s2;+3;1.23;1734;2993;8.79
68;Er;Erbium;167.26;lanth;s;f;;6;[Xe]4f12 6s2;+3;1.24;1802;3141;9.066
69;Tm;Thulium;168.93;lanth;s;f;;6;[Xe]4f13 6s2;+3;1.25;1818;2223;9.32
70;Yb;Ytterbium;173.05;lanth;s;f;;6;[Xe]4f14 6s2;+3,+2;;1097;1469;6.90
71;Lu;Lutetium;174.97;lanth;s;d;;6;[Xe]4f14 5d1 6s2;+3;1.27;1925;3675;9.841
72;Hf;Hafnium;178.49;transition;s;d;4;6;[Xe]4f14 5d2 6s2;+4;1.3;2506;4876;13.31
73;Ta;Tantalum;180.95;transition;s;d;5;6;[Xe]4f14 5d3 6s2;+5;1.5;3290;5731;16.69
74;W;Tungsten;183.84;transition;s;d;6;6;[Xe]4f14 5d4 6s2;+6,+4;2.36;3695;5828;19.25
75;Re;Rhenium;186.21;transition;s;d;7;6;[Xe]4f14 5d5 6s2;+7,+4;1.9;3459;5869;21.02
76;Os;Osmium;190.23;transition;s;d;8;6;[Xe]4f14 5d6 6s2;+4,+6;2.2;3306;5285;22.59
77;Ir;Iridium;192.22;transition;s;d;9;6;[Xe]4f14 5d7 6s2;+3,+4;2.20;2719;4701;22.56
78;Pt;Platinum;195.08;transition;s;d;10;6;[Xe]4f14 5d9 6s1;+2,+4;2.28;2041.4;4098;21.45
79;Au;Gold;196.97;transition;s;d;11;6;[Xe]4f14 5d10 6s1;+3,+1;2.54;1337.33;3129;19.30
80;Hg;Mercury;200.59;transition;l;d;12;6;[Xe]4f14 5d10 6s2;+2,+1;2.00;234.32;629.88;13.534
81;Tl;Thallium;204.38;postt;s;p;13;6;[Xe]4f14 5d10 6s2 6p1;+1,+3;1.62;577;1746;11.85
82;Pb;Lead;207.2;postt;s;p;14;6;[Xe]4f14 5d10 6s2 6p2;+2,+4;2.33;600.61;2022;11.34
83;Bi;Bismuth;208.98;postt;s;p;15;6;[Xe]4f14 5d10 6s2 6p3;+3,+5;2.02;544.7;1837;9.78
84;Po;Polonium;209;postt;s;p;16;6;[Xe]4f14 5d10 6s2 6p4;+4,+2;2.0;527;1235;9.20
85;At;Astatine;210;halogen;s;p;17;6;[Xe]4f14 5d10 6s2 6p5;-1,+1;2.2;575;610;
86;Rn;Radon;222;noble;g;p;18;6;[Xe]4f14 5d10 6s2 6p6;0;;202;211.5;
87;Fr;Francium;223;alkali;s;s;1;7;[Rn]7s1;+1;0.7;300;950;
88;Ra;Radium;226;alkaline;s;s;2;7;[Rn]7s2;+2;0.9;973;2010;5.5
89;Ac;Actinium;227;actin;s;d;;7;[Rn]6d1 7s2;+3;1.1;1323;3471;10.07
90;Th;Thorium;232.04;actin;s;f;;7;[Rn]6d2 7s2;+4;1.3;2115;5061;11.72
91;Pa;Protactinium;231.04;actin;s;f;;7;[Rn]5f2 6d1 7s2;+5,+4;1.5;1841;4300;15.37
92;U;Uranium;238.03;actin;s;f;;7;[Rn]5f3 6d1 7s2;+6,+4;1.38;1405.3;4404;19.1
93;Np;Neptunium;237;actin;s;f;;7;[Rn]5f4 6d1 7s2;+5,+4,+6;1.36;917;4273;20.45
94;Pu;Plutonium;244;actin;s;f;;7;[Rn]5f6 7s2;+4,+6,+3;1.28;912.5;3501;19.85
95;Am;Americium;243;actin;s;f;;7;[Rn]5f7 7s2;+3,+4;1.13;1449;2880;13.69
96;Cm;Curium;247;actin;s;f;;7;[Rn]5f7 6d1 7s2;+3;1.28;1613;3383;13.51
97;Bk;Berkelium;247;actin;s;f;;7;[Rn]5f9 7s2;+3,+4;1.3;1259;2900;14.79
98;Cf;Californium;251;actin;s;f;;7;[Rn]5f10 7s2;+3;1.3;1173;1743;15.1
99;Es;Einsteinium;252;actin;s;f;;7;[Rn]5f11 7s2;+3;1.3;1133;1269;8.84
100;Fm;Fermium;257;actin;s;f;;7;[Rn]5f12 7s2;+3;1.3;1800;;
101;Md;Mendelevium;258;actin;s;f;;7;[Rn]5f13 7s2;+3,+2;1.3;1100;;
102;No;Nobelium;259;actin;s;f;;7;[Rn]5f14 7s2;+2,+3;1.3;1100;;
103;Lr;Lawrencium;262;actin;s;d;;7;[Rn]5f14 7s2 7p1;+3;;1900;;
104;Rf;Rutherfordium;267;transition;s;d;4;7;[Rn]5f14 6d2 7s2;+4;;2400;5800;
105;Db;Dubnium;268;transition;u;d;5;7;[Rn]5f14 6d3 7s2;+5;;;;
106;Sg;Seaborgium;269;transition;u;d;6;7;[Rn]5f14 6d4 7s2;+6;;;;
107;Bh;Bohrium;270;transition;u;d;7;7;[Rn]5f14 6d5 7s2;+7;;;;
108;Hs;Hassium;269;transition;u;d;8;7;[Rn]5f14 6d6 7s2;+8;;;;
109;Mt;Meitnerium;278;unknown;u;d;9;7;[Rn]5f14 6d7 7s2;;;;;
110;Ds;Darmstadtium;281;unknown;u;d;10;7;[Rn]5f14 6d8 7s2;;;;;
111;Rg;Roentgenium;282;unknown;u;d;11;7;[Rn]5f14 6d9 7s2;;;;;
112;Cn;Copernicium;285;transition;u;d;12;7;[Rn]5f14 6d10 7s2;+2;;;;
113;Nh;Nihonium;286;postt;u;p;13;7;[Rn]5f14 6d10 7s2 7p1;+1;;;;
114;Fl;Flerovium;289;postt;u;p;14;7;[Rn]5f14 6d10 7s2 7p2;+2;;;;
115;Mc;Moscovium;290;postt;u;p;15;7;[Rn]5f14 6d10 7s2 7p3;;;;;
116;Lv;Livermorium;293;postt;u;p;16;7;[Rn]5f14 6d10 7s2 7p4;;;;;
117;Ts;Tennessine;294;halogen;u;p;17;7;[Rn]5f14 6d10 7s2 7p5;;;;;
118;Og;Oganesson;294;noble;u;p;18;7;[Rn]5f14 6d10 7s2 7p6;0;;;;
"""

func parseElements() -> [Element] {
    var out: [Element] = []
    for line in RAW_DATA.split(separator: "\n") {
        let f = line.components(separatedBy: ";")
        if f.count < 15 { continue }
        func d(_ s: String) -> Double? { let t = s.trimmingCharacters(in: .whitespaces); return t.isEmpty ? nil : Double(t) }
        let el = Element(
            z: Int(f[0])!,
            sym: f[1],
            name: f[2],
            mass: Double(f[3]) ?? 0,
            cat: Category(rawValue: f[4]) ?? .unknown,
            state: PhysState(rawValue: f[5]) ?? .u,
            block: f[6],
            group: Int(f[7].trimmingCharacters(in: .whitespaces)),
            period: Int(f[8]) ?? 0,
            econf: f[9],
            ox: f[10],
            en: d(f[11]),
            melt: d(f[12]),
            boil: d(f[13]),
            density: d(f[14])
        )
        out.append(el)
    }
    return out
}

let ELEMENTS = parseElements()

// MARK: - Layout constants

let CELL_W: CGFloat = 66
let CELL_H: CGFloat = 74
let CELL_SP: CGFloat = 3

// Typical ionic charge per main group (for the top header strip)
let groupCharge: [Int: String] = [
    1: "+1", 2: "+2", 13: "+3", 14: "±4", 15: "−3", 16: "−2", 17: "−1", 18: "0"
]

// MARK: - Cell

struct ElementCell: View {
    let el: Element
    let dim: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(el.z)").font(.system(size: 9, weight: .semibold))
                Spacer()
                if !el.ox.isEmpty {
                    Text(el.ox.replacingOccurrences(of: "-", with: "−"))
                        .font(.system(size: 7.5, weight: .medium))
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            Text(el.sym).font(.system(size: 21, weight: .bold))
            Text(el.name).font(.system(size: 7.5)).lineLimit(1).minimumScaleFactor(0.6)
            HStack {
                Text(String(format: "%.2f", el.mass)).font(.system(size: 9, weight: .medium))
                Spacer()
                Text(el.en.map { String(format: "%.2f", $0) } ?? "—").font(.system(size: 9, weight: .semibold)).opacity(0.85)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(width: CELL_W, height: CELL_H)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(el.cat.color.opacity(dim ? 0.18 : 0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(dim ? 0.05 : 0.18), lineWidth: 0.8)
        )
        .foregroundColor(dim ? .secondary : Color.black.opacity(0.85))
    }
}

struct EmptyCell: View {
    var body: some View { Color.clear.frame(width: CELL_W, height: CELL_H) }
}

struct PlaceholderCell: View {
    let label: String
    let cat: Category
    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .frame(width: CELL_W, height: CELL_H)
            .background(RoundedRectangle(cornerRadius: 6).fill(cat.color.opacity(0.35)))
            .foregroundColor(.secondary)
    }
}

// MARK: - Detail

struct DetailRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
            Text(value).font(.system(size: 12)).textSelection(.enabled)
            Spacer()
        }
    }
}

struct DetailView: View {
    let el: Element
    var onClose: () -> Void

    func kc(_ k: Double?) -> String {
        guard let k = k else { return "—" }
        return String(format: "%.2f K  (%.1f °C)", k, k - 273.15)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header band
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(el.sym).font(.system(size: 52, weight: .bold)).textSelection(.enabled)
                    Text(el.name).font(.title2.weight(.semibold)).textSelection(.enabled)
                    Text(el.cat.display).font(.subheadline).opacity(0.85)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Z = \(el.z)").font(.title3.weight(.bold))
                    Text("A ≈ \(el.massNumber)").font(.headline)
                    Text(el.state.glyph).font(.subheadline)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(el.cat.color.opacity(0.9))
            .foregroundColor(Color.black.opacity(0.85))

            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    DetailRow(label: "Atomic number (Z)", value: "\(el.z)")
                    DetailRow(label: "Mass number (A)", value: "≈ \(el.massNumber)  (most abundant isotope)")
                    DetailRow(label: "Relative atomic mass", value: String(format: "%.4g u", el.mass))
                    DetailRow(label: "Standard state (25 °C)", value: el.state.display)
                    DetailRow(label: "Classification", value: el.cat.display)
                    DetailRow(label: "Oxidation states", value: el.ox.isEmpty ? "—" : el.ox.replacingOccurrences(of: "-", with: "−"))
                    Divider().padding(.vertical, 2)
                    DetailRow(label: "Protons (p⁺)", value: "\(el.protons)")
                    DetailRow(label: "Neutrons (n⁰)", value: "\(el.neutrons)  (for A ≈ \(el.massNumber))")
                    DetailRow(label: "Electrons (e⁻)", value: "\(el.electrons)  (neutral atom)")
                    Divider().padding(.vertical, 2)
                    DetailRow(label: "Group", value: el.group.map { "\($0)" } ?? (el.cat == .lanth ? "Lanthanide series" : el.cat == .actin ? "Actinide series" : "—"))
                    DetailRow(label: "Period", value: "\(el.period)")
                    DetailRow(label: "Block", value: el.block + "-block")
                    DetailRow(label: "Differentiating subshell", value: el.subshell)
                    DetailRow(label: "Electron configuration (condensed)", value: el.econf)
                    DetailRow(label: "Electron configuration (full)", value: el.fullEconf)
                    Divider().padding(.vertical, 2)
                    DetailRow(label: "Electronegativity (Pauling)", value: el.en.map { String(format: "%.2f", $0) } ?? "—")
                    DetailRow(label: "Melting point", value: kc(el.melt))
                    DetailRow(label: "Boiling point", value: kc(el.boil))
                    DetailRow(label: "Density", value: el.density.map { String(format: "%.3f g/cm³", $0) } ?? "—")
                }
                .padding(20)
            }
        }
        .frame(width: 460, height: 600)
        // Keep keyboard dismissal (Esc / Enter) now that the button is gone.
        .overlay(
            Button("", action: onClose).keyboardShortcut(.cancelAction).hidden()
        )
        .overlay(
            Button("", action: onClose).keyboardShortcut(.defaultAction).hidden()
        )
    }
}

// MARK: - Legends

struct CategoryLegend: View {
    @Binding var selected: Category?
    let cats: [Category] = [.alkali, .alkaline, .transition, .postt, .metalloid, .nonmetal, .halogen, .noble, .lanth, .actin, .unknown]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let cols = [GridItem(.adaptive(minimum: 160), spacing: 6)]
            LazyVGrid(columns: cols, alignment: .leading, spacing: 4) {
                ForEach(cats, id: \.rawValue) { c in
                    Button(action: { selected = (selected == c) ? nil : c }) {
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 3).fill(c.color).frame(width: 13, height: 13)
                            Text(c.display).font(.system(size: 10))
                                .fontWeight(selected == c ? .bold : .regular)
                        }
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(selected == c ? c.color.opacity(0.22) : Color.clear))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(selected == c ? c.color : Color.clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            if selected != nil {
                Button(action: { selected = nil }) {
                    Text("Clear highlight").font(.system(size: 10)).foregroundColor(.secondary)
                }.buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Main grid

struct PeriodicGrid: View {
    let lookup: [Int: Element]   // key = row*100 + col
    let isHighlighted: (Element) -> Bool
    let filterActive: Bool
    let onTap: (Element) -> Void

    func cell(_ row: Int, _ col: Int) -> AnyView {
        // Group-3 placeholders for the f-block series
        if row == 6 && col == 3 { return AnyView(PlaceholderCell(label: "57–71", cat: .lanth)) }
        if row == 7 && col == 3 { return AnyView(PlaceholderCell(label: "89–103", cat: .actin)) }
        if let el = lookup[row * 100 + col] {
            let dim = filterActive && !isHighlighted(el)
            return AnyView(
                ElementCell(el: el, dim: dim)
                    .onTapGesture { onTap(el) }
                    .help("\(el.name) — \(el.cat.display)")
            )
        }
        return AnyView(EmptyCell())
    }

    func gridRow(_ row: Int) -> some View {
        HStack(spacing: CELL_SP) {
            ForEach(1...18, id: \.self) { col in cell(row, col) }
        }
    }

    var chargeHeader: some View {
        HStack(spacing: CELL_SP) {
            ForEach(1...18, id: \.self) { col in
                VStack(spacing: 1) {
                    Text("\(col)").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                    Text(groupCharge[col] ?? "var")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(groupCharge[col] == nil ? .secondary : .primary)
                }
                .frame(width: CELL_W)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CELL_SP) {
            Text("Typical ionic charge by group  ·  transition-metal charges are shown in each cell ↗")
                .font(.system(size: 10)).foregroundColor(.secondary)
            chargeHeader
            ForEach(1...7, id: \.self) { gridRow($0) }
            Spacer().frame(height: 10)
            HStack(spacing: CELL_SP) {
                Text("La / Ac\nseries").font(.system(size: 8)).foregroundColor(.secondary)
                    .frame(width: CELL_W * 2 + CELL_SP, height: CELL_H, alignment: .center)
                ForEach(3...18, id: \.self) { col in cell(9, col) }
            }
            HStack(spacing: CELL_SP) {
                Color.clear.frame(width: CELL_W * 2 + CELL_SP, height: CELL_H)
                ForEach(3...18, id: \.self) { col in cell(10, col) }
            }
        }
        .padding(16)
    }
}

// MARK: - Content

struct ContentView: View {
    @State private var search = ""
    @State private var selected: Element?
    @State private var selectedCategory: Category?

    var lookup: [Int: Element] {
        var d: [Int: Element] = [:]
        for el in ELEMENTS { let p = el.pos; d[p.row * 100 + p.col] = el }
        return d
    }

    func matches(_ el: Element) -> Bool {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return true }
        return el.name.lowercased().contains(q)
            || el.sym.lowercased() == q
            || el.sym.lowercased().hasPrefix(q)
            || "\(el.z)" == q
    }

    var filterActive: Bool {
        !search.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategory != nil
    }

    func isHighlighted(_ el: Element) -> Bool {
        let searchOK = search.trimmingCharacters(in: .whitespaces).isEmpty || matches(el)
        let catOK = selectedCategory == nil || el.cat == selectedCategory
        return searchOK && catOK
    }

    var searchResults: [Element] {
        let q = search.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return [] }
        return ELEMENTS.filter { matches($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Periodic Table").font(.title.weight(.bold))
                    Text("Cell: Z (top-left) · charges (top-right) · symbol · name · molar mass (bottom-left) · electronegativity (bottom-right)")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search by name or symbol (e.g. Iron, Fe, 26)", text: $search)
                        .textFieldStyle(.plain)
                        .frame(width: 280)
                    if !search.isEmpty {
                        Button(action: { search = "" }) { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
            }
            .padding(.horizontal, 16).padding(.top, 12)

            if !searchResults.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(searchResults.prefix(20)) { el in
                            Button(action: { selected = el }) {
                                HStack(spacing: 5) {
                                    Text(el.sym).fontWeight(.bold)
                                    Text(el.name).foregroundColor(.secondary)
                                }
                                .font(.system(size: 11))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 6).fill(el.cat.color.opacity(0.85)))
                                .foregroundColor(Color.black.opacity(0.85))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 16)
                }
            }

            ScrollView([.horizontal, .vertical]) {
                PeriodicGrid(
                    lookup: lookup,
                    isHighlighted: isHighlighted,
                    filterActive: filterActive,
                    onTap: { selected = $0 }
                )
            }

            CategoryLegend(selected: $selectedCategory).padding(.horizontal, 16).padding(.bottom, 12)
        }
        .frame(minWidth: 1180, minHeight: 820)
        .overlay {
            if let el = selected {
                ZStack {
                    // Dimmed backdrop — click anywhere outside the panel to dismiss.
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { selected = nil }
                    DetailView(el: el) { selected = nil }
                        .background(Color(NSColor.windowBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 30)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selected != nil)
    }
}

// MARK: - App

@main
struct PeriodicTableApp: App {
    var body: some Scene {
        WindowGroup("Periodic Table") {
            ContentView()
        }
        .defaultSize(width: 1260, height: 880)
    }
}
