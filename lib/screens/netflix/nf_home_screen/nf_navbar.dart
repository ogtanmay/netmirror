import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/widgets/ott_drawer.dart';

class _CustomNavItem {
  const _CustomNavItem({
    required this.icon,
    required this.uIcon,
    required this.label,
  });

  final Widget icon;
  final Widget uIcon;
  final String label;
}

class NfNavBar extends StatelessWidget {
  const NfNavBar({super.key, required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sClr = cs.onSurface;
    final usClr = cs.onSurface.withValues(alpha: 0.45);

    final imgWidget = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.asset(
        "assets/logos/netflix-profile-logo.png",
        height: 20,
        width: 20,
      ),
    );

    final items = [
      _CustomNavItem(
        icon: Icon(Icons.home, color: sClr),
        uIcon: Icon(Icons.home_outlined, color: usClr),
        label: "Home",
      ),
      _CustomNavItem(
        uIcon: Icon(HugeIcons.strokeRoundedMenuSquare, color: usClr),
        icon: Icon(HugeIcons.strokeRoundedGameController03, color: usClr),
        label: "OTT",
      ),
      _CustomNavItem(
        icon: Icon(CupertinoIcons.add, color: sClr),
        uIcon: Icon(Icons.search, color: usClr),
        label: "New & Hot",
      ),
      _CustomNavItem(
        icon: Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border.all(width: 1.5, color: sClr),
            borderRadius: BorderRadius.circular(3),
          ),
          child: imgWidget,
        ),
        uIcon: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: imgWidget,
        ),
        label: "My Profile",
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.15), width: 0.5),
        ),
      ),
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.mapIndexed((i, item) {
          final isSelected = i == current;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (i == 0 && current != 0) {
                  GoRouter.of(context).push("/");
                } else if (i == 1) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) => OttDrawer(selectedOtt: 0),
                  );
                } else if (i == 3 && current != 3) {
                  GoRouter.of(context).push("/profile");
                } else if (i == 2) {
                  GoRouter.of(context).push("/search/0");
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isSelected ? item.icon : item.uIcon,
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? sClr : usClr,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    // return Row(
    //   children: [
    //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    //     BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: "Games"),
    //     BottomNavigationBarItem(icon: Icon(Icons.video_settings), label: "Hot"),
    //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "My Profile"),
    //   ],
    //   currentIndex: 0,
    //   unselectedIconTheme: IconThemeData(color: Colors.white60),
    //   selectedIconTheme: IconThemeData(color: Colors.white),
    //   selectedItemColor: Colors.white,
    //   unselectedItemColor: Colors.white60,
    //   unselectedLabelStyle: TextStyle(color: Colors.white),
    // );
  }
}
