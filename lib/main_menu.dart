import 'package:flutter/material.dart';
import 'mylib/mywidgets.dart';

/// // ---------------- Route names ----------------
const String routeAppointments = '/appointments';
const String routeLeaves = '/leaves';
const String routeCreateDoc = '/createdoc';
const String routeLogBook = '/logbook';
const String routeSettings = '/settings';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_MenuEntry>[
      const _MenuEntry('Διαχείριση Ραντεβού', routeAppointments),
      //     const _MenuEntry('Διαχείριση Αδειών', routeLeaves),
      const _MenuEntry('Δημιουργία Εγγράφου', routeCreateDoc),
      const _MenuEntry('Καταγραφή Ημερολογίου Συμβάντων', routeLogBook),
      const _MenuEntry('Ρυθμίσεις', routeSettings),
    ];

    return Column(
      children: [
        // ─────────────────── ΠΑΝΩ BorderedBox ───────────────────
        Flexible(
          flex: 6,
          child: BorderedBox(
            // ► Μηδενίζουμε όλα τα “εξτρά” padding εδώ,
            //    θα βάλουμε ό,τι χρειάζεται απευθείας στο ListView.
            // outerPadding: EdgeInsets.zero,
            innerPadding: EdgeInsets.zero,

            child: LayoutBuilder(
              builder: (context, constraints) {
                // --- ρυθμίσεις ---
                const double separator = 12; // κενό μεταξύ καρτών
                const double vPad = 16; // πάνω + κάτω (8 + 8) που ΘΕΛΟΥΜΕ

                // --- διαθέσιμο ύψος για ΟΛΑ τα στοιχεία ---
                final double totalSpacing = separator * (entries.length - 1);
                const double totalPadding = vPad; // top+bottom συνολικά
                final double itemHeight =
                    (constraints.maxHeight - totalSpacing - totalPadding) /
                    entries.length;

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    vertical: vPad / 2,
                    horizontal: 16,
                  ),
                  itemCount: entries.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(height: separator),
                  itemBuilder:
                      (_, index) => SizedBox(
                        height: itemHeight,
                        child: _MenuCard(entry: entries[index]),
                      ),
                );
              },
            ),
          ),
        ),

        // ─────────────────── ΚΑΤΩ BorderedBox ───────────────────
        const Flexible(
          flex: 4,
          child: BorderedBox(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Διπλωματική Εργάσια με θέμα:\n'),
                  Text(
                    'Σχεδίαση και Ανάπτυξη Εφαρμογής Κινητού',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'για την Οργάνωση και Υποστήριξη',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'της Διοίκησης Σχολικής Μονάδας\n\n\n\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('του μεταταπτυχιακού φοιτητή'),
                  Text(
                    'Βεζονιαράκη Δημήτρη\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Επιβλέπον Καθηγητής'),
                  Text(
                    'Τσιλίκας Νικόλαος',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Εσωτερικό μοντέλο για κάθε επιλογή μενού
class _MenuEntry {
  final String title;
  final String route;
  const _MenuEntry(this.title, this.route);
}

/// Κάρτα που αντιπροσωπεύει μια επιλογή του μενού
class _MenuCard extends StatelessWidget {
  final _MenuEntry entry;
  const _MenuCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => Navigator.pushNamed(context, entry.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(
            child: Text(
              entry.title,
              style: TextStyle(
                fontSize: 18,
                //fontWeight: FontWeight.w500,
                fontWeight: FontWeight.lerp(
                  FontWeight.w500,
                  FontWeight.w600,
                  0.5,
                ),
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
