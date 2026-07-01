import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/data/options.dart';

class OTTModel {
  final String name;
  final String image;
  final String route;
  const OTTModel({
    required this.name,
    required this.image,
    required this.route,
  });
}

const ottList = [
  OTTModel(
    name: "Netflix",
    image: "assets/ott-list/nf.webp",
    route: "/nf-home",
  ),
  OTTModel(
    name: "Prime Video",
    image: "assets/ott-list/pv.jpg",
    route: "/pv-home",
  ),
  OTTModel(
    name: "Jio Hotstar",
    image: "assets/ott-list/jio-hotstar.jpg",
    route: "/hotstar-home",
  ),
];

int getOttIndexFromRoute(String route) {
  for (int i = 0; i < ottList.length; i++) {
    if (ottList[i].route == route) return i;
  }
  return -1;
}

class OttDrawer extends StatelessWidget {
  final selectedOtt;
  OttDrawer({super.key, this.selectedOtt = 0});

  final controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        final cs = Theme.of(context).colorScheme;
        return Column(
          children: [
            // M3 drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Choose Platform",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: ottList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final isSelected = selectedOtt == index;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (!isSelected) {
                        SettingsOptions.currentScreen = ottList[index].route;
                        GoRouter.of(context).go(ottList[index].route);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? cs.primary : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          ottList[index].image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
