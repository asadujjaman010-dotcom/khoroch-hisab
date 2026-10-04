import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const owner = 'Asadujjaman Munna';
const mn = ['January','February','March','April','May','June','July','August','September','October','November','December'];
const cats = ['Baba','Ma','Bou','Sontan','Mobile Bill','Nijer Thaka-Khawa','Jama-Kapor','Ashik Store Baki','Onnanno Khoroch'];
const kha = 'Ashik Store Baki', ksh = 'Ashik Store Shodh', onn = 'Onnanno Khoroch';
const eCats = [...cats, ksh];

class E {
  DateTime d; String c, n; double a;
  E(this.d, this.c, this.a, [this.n = '']);
  Map<String, dynamic> toJson() => {'d': d.toIso8601String(), 'c': c, 'a': a, 'n': n};
  static E f(dynamic m) => E(DateTime.parse(m['d']), m['c'], (m['a'] as num).toDouble(), m['n'] ?? '');
}

String fm(double v) => (v < 0 ? '-' : '') + v.abs().round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
String dt(DateTime d) => '${d.day}/${d.month}/${d.year}';
Color? rc(String r) => r == 'Paid' ? Colors.green : r == 'Baki' ? Colors.red : r.isEmpty ? null : Colors.orange;

void main() => runApp(MaterialApp(
    title: 'Khoroch Hisab',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF1F3864), useMaterial3: true),
    home: const Home()));

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _H();
}

class _H extends State<Home> {
  List<E> es = [], dn = [], ds = [];
  int year = 2026, day = 8, start = 9, k = 8, tab = 0;
  List<double> op = [0, 0, 0], sal = List.filled(12, 0.0), oth = List.filled(12, 0.0), bud = List.filled(9, 0.0);
  SharedPreferences? sp;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    sp = await SharedPreferences.getInstance();
    final m = jsonDecode(sp!.getString('d') ?? '{}') as Map;
    List<E> le(String x) => ((m[x] ?? []) as List).map((e) => E.f(e)).toList();
    List<double> ld(String x, int n) => m[x] == null ? List.filled(n, 0.0) : (m[x] as List).map((e) => (e as num).toDouble()).toList();
    es = le('es'); dn = le('dn'); ds = le('ds');
    year = m['year'] ?? 2026; day = m['day'] ?? 8; start = m['start'] ?? 9;
    op = ld('op', 3); sal = ld('sal', 12); oth = ld('oth', 12); bud = ld('bud', 9);
    final n = DateTime.now();
    k = (n.year == year ? n.month - 1 + (n.day < day ? -1 : 0) : start - 1).clamp(0, 11).toInt();
    setState(() {});
  }
  void _save() {
    sp?.setString('d', jsonEncode({'es': es, 'dn': dn, 'ds': ds, 'year': year, 'day': day, 'start': start, 'op': op, 'sal': sal, 'oth': oth, 'bud': bud}));
    setState(() {});
  }

  DateTime st(int i) => DateTime(year, i + 1, day);
  DateTime en(int i) => DateTime(year, i + 2, day);
  bool inC(E e, int i) => !e.d.isBefore(st(i)) && e.d.isBefore(en(i));
  double S(List<E> l, int i, [bool Function(E)? f]) => l.where((e) => inC(e, i) && (f == null || f(e))).fold(0.0, (p, e) => p + e.a);
  double tot(List<E> l, bool Function(E) f) => l.where(f).fold(0.0, (p, e) => p + e.a);

  // [income, dharNilam, khoroch, dharShodh, storeBaki, storeShodh, savings, dhar, store, net]
  List<List<double>> yr() {
    final r = <List<double>>[];
    double sv = op[0], dh = op[1], sk = op[2];
    for (var i = 0; i < 12; i++) {
      final inc = sal[i] + oth[i], nil = S(dn, i), kh = S(es, i, (e) => cats.contains(e.c)), dsh = S(ds, i);
      final a = S(es, i, (e) => e.c == kha), b = S(es, i, (e) => e.c == ksh), on = i >= start - 1;
      if (on) { sv += inc + nil - kh + a - dsh - b; dh += nil - dsh; sk += a - b; }
      r.add([inc, nil, kh, dsh, a, b, on ? sv : 0, on ? dh : 0, on ? sk : 0, on ? sv - dh - sk : 0]);
    }
    return r;
  }

  String rem(E e) {
    if (e.c == ksh) return 'Paid';
    if (e.c != kha) return '';
    final all = [...es]..sort((a, b) => a.d.compareTo(b.d));
    double tk = op[2];
    for (final x in all) { if (x.c == kha) tk += x.a; if (identical(x, e)) break; }
    final rep = tot(es, (x) => x.c == ksh);
    return rep >= tk ? 'Paid' : rep > tk - e.a ? 'Partly Paid' : 'Baki';
  }
  String nm(E e) => e.n.trim().toLowerCase();
  String drem(E e) {
    final all = [...dn]..sort((a, b) => a.d.compareTo(b.d));
    double prior = 0;
    for (final x in all) { if (identical(x, e)) break; if (nm(x) == nm(e)) prior += x.a; }
    final paid = (tot(ds, (x) => nm(x) == nm(e)) - prior).clamp(0, e.a).toDouble();
    return paid >= e.a ? 'Paid' : paid > 0 ? 'Partly Paid' : 'Baki';
  }

  Widget row(String t, double v, {bool bold = false, Color? c, String? sub}) => ListTile(
      dense: true,
      title: Text(t, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
      subtitle: sub == null ? null : Text(sub),
      trailing: Text(fm(v), style: TextStyle(fontWeight: bold ? FontWeight.bold : null, color: c)));
  Widget head(String t) => Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 2), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F3864))));

  Widget monthly() {
    final y = yr(), r = y[k], on = k >= start - 1;
    final p = k == start - 1 ? op : k > start - 1 ? [y[k - 1][6], y[k - 1][7], y[k - 1][8]] : [0.0, 0.0, 0.0];
    final net = r[9], cv = [for (final c in cats) S(es, k, (e) => e.c == c)];
    final ce = es.where((e) => inC(e, k)).toList();
    final bsum = bud.fold(0.0, (a, b) => a + b);
    return ListView(padding: const EdgeInsets.only(bottom: 80), children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text('${mn[k]}: ${dt(st(k))} theke ${dt(en(k).subtract(const Duration(days: 1)))}', style: const TextStyle(color: Colors.grey))),
      Card(
          margin: const EdgeInsets.all(12),
          color: !on ? Colors.grey.shade200 : net >= 0 ? Colors.green.shade100 : Colors.red.shade100,
          child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Text(!on ? 'Ei mash hisab shuru r age' : net > 0 ? 'SAVINGS e achho: ${fm(net)} taka' : net < 0 ? 'DHAR / BAKI te achho: ${fm(-net)} taka' : 'Barabori: 0 taka',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Jomano ${fm(r[6])} | Dhar ${fm(r[7])} | Ashik Store baki ${fm(r[8])}', textAlign: TextAlign.center),
          ]))),
      head('1) Ei mash e ki ashlo'),
      row('Salary', sal[k]), row('Onno income', oth[k]), row('Dhar nilam (Dhar sheet theke)', r[1]),
      row('Mot ashlo', sal[k] + oth[k] + r[1], bold: true),
      head('2) Khoroch (category wise) ar budget'),
      for (var i = 0; i < 9; i++)
        row(cats[i], cv[i], c: bud[i] > 0 && cv[i] > bud[i] ? Colors.red : null, sub: bud[i] > 0 ? 'Budget ${fm(bud[i])}  |  baki ${fm(bud[i] - cv[i])}' : null),
      row('Mot khoroch (Ashik Store baki shoho)', r[2], bold: true, c: bsum > 0 && r[2] > bsum ? Colors.red : null, sub: bsum > 0 ? 'Budget ${fm(bsum)}  |  baki ${fm(bsum - r[2])}' : null),
      head('3) Cash er hisab'),
      row('Cash khoroch (Ashik Store baki bade)', r[2] - cv[7]), row('Dhar shodh dilam', r[3]), row('Ashik Store baki shodh dilam', r[5]),
      row('Mot cash bahir hoyeche', r[2] - cv[7] + r[3] + r[5], bold: true),
      head('4) Mash er position (auto carry-forward)'),
      row('Savings: ager mash theke ashlo', p[0]), row('Savings: mash shesh', r[6], bold: true),
      row('Dhar baki: ager mash theke', p[1]), row('Dhar baki: mash shesh', r[7], bold: true),
      row('Ashik Store baki: ager mash theke', p[2]), row('Ashik Store baki: mash shesh', r[8], bold: true),
      row('Net (Savings - Dhar - Baki)', r[9], bold: true),
      head('5) Ashik Store hisab (ei mash)'),
      row('Ager mash porjonto baki', p[2]), row('Ei mash e baki khailam', r[4]),
      row('Koybar baki khailam (entry)', ce.where((e) => e.c == kha).length.toDouble()),
      row('Ei mash e shodh dilam', r[5]), row('Ekhon mot baki', r[8], bold: true),
      head('6) Onnanno khoroch er list'),
      for (final e in ce.where((e) => e.c == onn)) ListTile(dense: true, title: Text(e.n.isEmpty ? '(biboron nai)' : e.n), subtitle: Text(dt(e.d)), trailing: Text(fm(e.a))),
    ]);
  }

  Widget yearly() {
    final y = yr();
    const h = ['Mash', 'Income', 'Dhar Nilam', 'Mot Khoroch', 'Dhar Shodh', 'Store Baki Khailam', 'Store Shodh', 'Savings', 'Dhar Baki', 'Store Baki', 'Net', 'Obostha'];
    String ob(int i) => i < start - 1 || y[i].take(6).every((x) => x == 0) ? '-' : y[i][9] > 0 ? 'Savings e' : y[i][9] < 0 ? 'Dhar e' : 'Barabori';
    return ListView(children: [
      head('Yearly Tracker $year'),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 14, columns: [for (final x in h) DataColumn(label: Text(x))], rows: [
        for (var i = 0; i < 12; i++)
          DataRow(cells: [
            DataCell(Text(mn[i])),
            for (var j = 0; j < 10; j++) DataCell(Text(fm(y[i][j]), style: TextStyle(color: j == 9 && y[i][9] != 0 ? (y[i][9] > 0 ? Colors.green : Colors.red) : null))),
            DataCell(Text(ob(i), style: TextStyle(fontWeight: FontWeight.bold, color: ob(i) == 'Savings e' ? Colors.green : ob(i) == 'Dhar e' ? Colors.red : null))),
          ]),
      ])),
      head('Category wise khoroch (budget er beshi hole lal)'),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 14, columns: [const DataColumn(label: Text('Mash')), for (final c in cats) DataColumn(label: Text(c)), const DataColumn(label: Text('Mot'))], rows: [
        for (var i = 0; i < 12; i++)
          DataRow(cells: [
            DataCell(Text(mn[i])),
            for (var j = 0; j < 9; j++) () { final v = S(es, i, (e) => e.c == cats[j]); return DataCell(Text(fm(v), style: TextStyle(color: bud[j] > 0 && v > bud[j] ? Colors.red : null))); }(),
            DataCell(Text(fm(y[i][2]), style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
        DataRow(cells: [const DataCell(Text('Budget')), for (final b in bud) DataCell(Text(fm(b))), DataCell(Text(fm(bud.fold(0.0, (a, b) => a + b))))]),
      ])),
    ]);
  }

  Widget entries() {
    final ce = es.where((e) => inC(e, k)).toList()..sort((a, b) => b.d.compareTo(a.d));
    if (ce.isEmpty) return const Center(child: Text('Kono entry nai. + chapo.'));
    return ListView(children: [
      for (final e in ce)
        Dismissible(key: ValueKey(e), direction: DismissDirection.endToStart, background: Container(color: Colors.red),
            onDismissed: (_) { es.remove(e); _save(); },
            child: ListTile(
                title: Text('${e.c}   ${fm(e.a)}'),
                subtitle: Text('${dt(e.d)}${e.n.isEmpty ? '' : '  |  ${e.n}'}'),
                trailing: Text(rem(e), style: TextStyle(fontWeight: FontWeight.bold, color: rc(rem(e)))))),
    ]);
  }

  Widget dhar() {
    final m = <String, List<double>>{};
    for (final e in dn) { m.putIfAbsent(e.n.trim(), () => [0, 0])[0] += e.a; }
    for (final e in ds) { m.putIfAbsent(e.n.trim(), () => [0, 0])[1] += e.a; }
    final nil = tot(dn, (e) => true), sh = tot(ds, (e) => true), t = op[1] + nil - sh;
    Widget lst(List<E> l, bool nilam) => Column(children: [
          for (final e in ([...l]..sort((a, b) => b.d.compareTo(a.d))))
            Dismissible(key: ValueKey(e), direction: DismissDirection.endToStart, background: Container(color: Colors.red),
                onDismissed: (_) { l.remove(e); _save(); },
                child: ListTile(dense: true, title: Text('${e.n.isEmpty ? '(naam nai)' : e.n}   ${fm(e.a)}'), subtitle: Text(dt(e.d)),
                    trailing: Text(nilam ? drem(e) : 'Paid', style: TextStyle(fontWeight: FontWeight.bold, color: rc(nilam ? drem(e) : 'Paid'))))),
        ]);
    return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
      Card(margin: const EdgeInsets.all(12), color: t > 0 ? Colors.red.shade100 : Colors.green.shade100,
          child: Padding(padding: const EdgeInsets.all(16), child: Text(t > 0 ? 'Tomar ekhon dhar baki ache: ${fm(t)} taka' : t < 0 ? 'Beshi shodh deya hoyeche, naam check koro' : 'Kono dhar baki nai',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
      row('Shuru-r dhar baki (Setup theke)', op[1]), row('Hisab shuru theke mot dhar nilam', nil), row('Mot dhar shodh dilam', sh), row('Ekhon mot dhar baki', t, bold: true),
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: FilledButton(onPressed: () => add(1), child: const Text('+ Dhar Nilam'))), const SizedBox(width: 12),
        Expanded(child: FilledButton.tonal(onPressed: () => add(2), child: const Text('+ Dhar Shodh'))),
      ])),
      head('Kar kache koto baki'),
      for (final x in m.entries) row(x.key.isEmpty ? '(naam nai)' : x.key, x.value[0] - x.value[1], bold: true, c: x.value[0] - x.value[1] > 0 ? Colors.red : Colors.green, sub: 'Nilam ${fm(x.value[0])} | Shodh ${fm(x.value[1])}'),
      head('Dhar nilam (je dhar niyecho)'), lst(dn, true),
      head('Dhar shodh (je dhar dilam)'), lst(ds, false),
    ]);
  }

  // mode 0 = entry, 1 = dhar nilam, 2 = dhar shodh
  void add(int mode) async {
    var d = DateTime.now(), c = cats[0];
    final a = TextEditingController(), n = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
        title: Text(mode == 0 ? 'Notun entry' : mode == 1 ? 'Dhar nilam' : 'Dhar shodh'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton(onPressed: () async {
            final p = await showDatePicker(context: ctx, initialDate: d, firstDate: DateTime(2020), lastDate: DateTime(2035));
            if (p != null) ss(() => d = p);
          }, child: Text('Tarikh: ${dt(d)}')),
          if (mode == 0) DropdownButton<String>(isExpanded: true, value: c, items: [for (final x in eCats) DropdownMenuItem(value: x, child: Text(x))], onChanged: (v) => ss(() => c = v!)),
          TextField(controller: a, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Taka')),
          TextField(controller: n, decoration: InputDecoration(labelText: mode == 0 ? 'Biboron (optional)' : mode == 1 ? 'Kar theke (naam)' : 'Kar kache (naam)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batil')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ])));
    final v = double.tryParse(a.text);
    if (ok == true && v != null && v > 0) {
      final e = E(DateTime(d.year, d.month, d.day), mode == 0 ? c : '', v, n.text);
      (mode == 0 ? es : mode == 1 ? dn : ds).add(e);
      _save();
    }
  }

  Widget tf(TextEditingController c, String l) => TextField(controller: c, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l));

  void setup() async {
    TextEditingController t(double x) => TextEditingController(text: x == 0 ? '' : x.round().toString());
    final yc = TextEditingController(text: '$year'), dc = TextEditingController(text: '$day');
    final oc = op.map(t).toList(), sc = sal.map(t).toList(), tc = oth.map(t).toList(), bc = bud.map(t).toList();
    var s = start;
    List<double> pv(List<TextEditingController> l) => [for (final c in l) double.tryParse(c.text) ?? 0.0];
    await Navigator.push(context, MaterialPageRoute(builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Scaffold(
        appBar: AppBar(title: const Text('Setup'), actions: [
          TextButton(onPressed: () {
            year = int.tryParse(yc.text) ?? year; day = int.tryParse(dc.text) ?? day; start = s;
            op = pv(oc); sal = pv(sc); oth = pv(tc); bud = pv(bc);
            _save(); Navigator.pop(ctx);
          }, child: const Text('Save')),
        ]),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          tf(yc, 'Bochhor (Year)'), tf(dc, 'Mash shuru hoy (tarikh)'),
          DropdownButton<int>(isExpanded: true, value: s, items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text('Hisab shuru: ${mn[i - 1]}'))], onChanged: (v) => ss(() => s = v!)),
          head('Shuru-r hisab (hisab shuru mash er shuru tarikhe)'),
          for (var i = 0; i < 3; i++) tf(oc[i], ['Joma (savings)', 'Dhar baki', 'Ashik Store baki'][i]),
          head('Salary / Onno income (je mash e hate pabe sei mash e)'),
          for (var i = 0; i < 12; i++) Row(children: [SizedBox(width: 50, child: Text(mn[i].substring(0, 3))), Expanded(child: tf(sc[i], 'Salary')), const SizedBox(width: 8), Expanded(child: tf(tc[i], 'Onno income'))]),
          head('Mashik budget (khali = alert nai)'),
          for (var i = 0; i < 9; i++) tf(bc[i], cats[i]),
          const SizedBox(height: 40),
        ])))));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [monthly(), yearly(), entries(), dhar()];
    return Scaffold(
        appBar: AppBar(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text(owner, style: TextStyle(fontSize: 14)),
              Text('Khoroch Hisab', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            actions: [
              if (tab == 0 || tab == 2)
                DropdownButtonHideUnderline(child: DropdownButton<int>(value: k, items: [for (var i = 0; i < 12; i++) DropdownMenuItem(value: i, child: Text(mn[i]))], onChanged: (v) => setState(() => k = v!))),
              IconButton(icon: const Icon(Icons.settings), onPressed: setup),
            ]),
        body: pages[tab],
        floatingActionButton: tab == 2 ? FloatingActionButton(onPressed: () => add(0), child: const Icon(Icons.add)) : null,
        bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Monthly'),
          NavigationDestination(icon: Icon(Icons.table_chart), label: 'Yearly'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Entries'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Dhar'),
        ]));
  }
}
