import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const owner = 'Asadujjaman Munna';
const cycleDay = 8;
const mn = ['January','February','March','April','May','June','July','August','September','October','November','December'];
const expCats = ['Baba','Ma','Bou','Sontan','Mobile Bill','Nijer Thaka-Khawa','Jama-Kapor','Ashik Store Baki','Onnanno Khoroch'];
const allCats = [...expCats, 'Salary', 'Onno Income', 'Dhar Nilam', 'Dhar Shodh', 'Ashik Store Shodh'];

class E {
  DateTime d; String c; double a; String n;
  E(this.d, this.c, this.a, this.n);
  Map<String, dynamic> toJson() => {'d': d.toIso8601String(), 'c': c, 'a': a, 'n': n};
  static E from(Map m) => E(DateTime.parse(m['d']), m['c'], (m['a'] as num).toDouble(), m['n'] ?? '');
}

String fm(double v) => (v < 0 ? '-' : '') + v.abs().round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'Khoroch Hisab',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1F3864), useMaterial3: true),
        home: const Home());
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _H();
}

class _H extends State<Home> {
  List<E> es = [];
  List<double> op = [0, 0, 0];
  int k = 0, tab = 0;
  SharedPreferences? sp;

  DateTime st(int i) => DateTime(2026, 9 + i, cycleDay);
  int get cur {
    final n = DateTime.now();
    var i = (n.year - 2026) * 12 + n.month - 9;
    if (n.day < cycleDay) i--;
    return i < 0 ? 0 : i;
  }
  String lab(int i) => mn[st(i).month - 1];

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    sp = await SharedPreferences.getInstance();
    es = (jsonDecode(sp!.getString('es') ?? '[]') as List).map((x) => E.from(x)).toList();
    op = (sp!.getStringList('op') ?? ['0', '0', '0']).map(double.parse).toList();
    k = cur;
    setState(() {});
  }
  void _save() {
    sp?.setString('es', jsonEncode(es.map((e) => e.toJson()).toList()));
    sp?.setStringList('op', op.map((x) => x.toString()).toList());
    setState(() {});
  }

  List<E> cyc() => es.where((e) => !e.d.isBefore(st(k)) && e.d.isBefore(st(k + 1))).toList();

  List<double> pos(DateTime upTo) {
    double s = op[0], d = op[1], b = op[2];
    for (final e in es) {
      if (e.d.isBefore(st(0)) || !e.d.isBefore(upTo)) continue;
      switch (e.c) {
        case 'Salary': case 'Onno Income': s += e.a; break;
        case 'Dhar Nilam': s += e.a; d += e.a; break;
        case 'Dhar Shodh': s -= e.a; d -= e.a; break;
        case 'Ashik Store Shodh': s -= e.a; b -= e.a; break;
        case 'Ashik Store Baki': b += e.a; break;
        default: s -= e.a;
      }
    }
    return [s, d, b];
  }

  Widget row(String t, double v, {bool bold = false}) => ListTile(
      dense: true,
      title: Text(t, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
      trailing: Text(fm(v), style: TextStyle(fontWeight: bold ? FontWeight.bold : null)));

  Widget monthly() {
    final ce = cyc(), a = pos(st(k)), z = pos(st(k + 1));
    final net = z[0] - z[1] - z[2], net0 = a[0] - a[1] - a[2];
    double sum(bool Function(E) f) => ce.where(f).fold(0.0, (p, e) => p + e.a);
    final inc = sum((e) => e.c == 'Salary' || e.c == 'Onno Income');
    final nil = sum((e) => e.c == 'Dhar Nilam');
    final tot = sum((e) => expCats.contains(e.c));
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
          color: net >= 0 ? Colors.green.shade100 : Colors.red.shade100,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(net > 0 ? 'SAVINGS e achho: ${fm(net)} taka' : net < 0 ? 'DHAR / BAKI te achho: ${fm(-net)} taka' : 'Barabori: 0 taka',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Jomano ${fm(z[0])} | Dhar ${fm(z[1])} | Ashik Store baki ${fm(z[2])}'),
              ]))),
      row('Ager mash theke ashlo (Net)', net0),
      row('Salary + Onno income', inc),
      row('Dhar nilam', nil),
      const Divider(),
      for (final c in expCats) row(c, sum((e) => e.c == c)),
      row('Mot khoroch (Ashik Store baki shoho)', tot, bold: true),
    ]);
  }

  Widget entries() {
    final ce = cyc()..sort((a, b) => b.d.compareTo(a.d));
    if (ce.isEmpty) return const Center(child: Text('Kono entry nai. + chapo.'));
    return ListView(children: [
      for (final e in ce)
        Dismissible(
            key: ValueKey(e),
            direction: DismissDirection.endToStart,
            background: Container(color: Colors.red),
            onDismissed: (_) { es.remove(e); _save(); },
            child: ListTile(
                title: Text('${e.c}   ${fm(e.a)}'),
                subtitle: Text('${e.d.day}/${e.d.month}/${e.d.year}${e.n.isEmpty ? '' : '  |  ${e.n}'}'))),
    ]);
  }

  Widget dhar() {
    final m = <String, double>{};
    for (final e in es) {
      if (e.c == 'Dhar Nilam' || e.c == 'Dhar Shodh') {
        final n = e.n.trim().isEmpty ? '(naam nai)' : e.n.trim();
        m[n] = (m[n] ?? 0) + (e.c == 'Dhar Nilam' ? e.a : -e.a);
      }
    }
    final t = op[1] + m.values.fold(0.0, (p, v) => p + v);
    return ListView(children: [
      ListTile(
          tileColor: t > 0 ? Colors.red.shade100 : Colors.green.shade100,
          title: const Text('Ekhon mot dhar baki', style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(fm(t))),
      ListTile(dense: true, title: const Text('Shuru-r (ager) dhar'), trailing: Text(fm(op[1]))),
      for (final x in m.entries)
        ListTile(title: Text(x.key), subtitle: Text(x.value <= 0 ? 'Paid' : 'Baki'), trailing: Text(fm(x.value))),
    ]);
  }

  void add() async {
    DateTime d = DateTime.now();
    String c = expCats[0];
    final a = TextEditingController(), n = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (ctx, ss) => AlertDialog(
                    title: const Text('Notun entry'),
                    content: SingleChildScrollView(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(
                          onPressed: () async {
                            final p = await showDatePicker(context: ctx, initialDate: d, firstDate: DateTime(2026, 9, 1), lastDate: DateTime(2030));
                            if (p != null) ss(() => d = p);
                          },
                          child: Text('Tarikh: ${d.day}/${d.month}/${d.year}')),
                      DropdownButton<String>(
                          isExpanded: true,
                          value: c,
                          items: [for (final x in allCats) DropdownMenuItem(value: x, child: Text(x))],
                          onChanged: (v) => ss(() => c = v!)),
                      TextField(controller: a, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Taka')),
                      TextField(controller: n, decoration: InputDecoration(labelText: c.startsWith('Dhar') ? 'Kar naam' : 'Biboron (optional)')),
                    ])),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batil')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                    ])));
    final v = double.tryParse(a.text);
    if (ok == true && v != null && v > 0) {
      es.add(E(DateTime(d.year, d.month, d.day), c, v, n.text));
      _save();
    }
  }

  void settings() async {
    final cs = [for (final x in op) TextEditingController(text: x == 0 ? '' : x.round().toString())];
    const names = ['Joma (savings)', 'Dhar baki', 'Ashik Store baki'];
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Shuru-r hisab (8 Sep 2026)'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < 3; i++)
                    TextField(controller: cs[i], keyboardType: TextInputType.number, decoration: InputDecoration(labelText: names[i])),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batil')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                ]));
    if (ok == true) { op = [for (final c in cs) double.tryParse(c.text) ?? 0]; _save(); }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [monthly(), entries(), dhar()];
    return Scaffold(
        appBar: AppBar(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text(owner, style: TextStyle(fontSize: 14)),
              Text('Khoroch Hisab', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            actions: [
              if (tab < 2)
                DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                        value: k,
                        items: [for (var i = 0; i <= cur + 1; i++) DropdownMenuItem(value: i, child: Text(lab(i)))],
                        onChanged: (v) => setState(() => k = v!))),
              IconButton(icon: const Icon(Icons.settings), onPressed: settings),
            ]),
        body: pages[tab],
        floatingActionButton: FloatingActionButton(onPressed: add, child: const Icon(Icons.add)),
        bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard), label: 'Monthly'),
              NavigationDestination(icon: Icon(Icons.list), label: 'Entries'),
              NavigationDestination(icon: Icon(Icons.people), label: 'Dhar'),
            ]));
  }
}
