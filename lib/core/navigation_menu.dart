import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class NavigationMenu extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const NavigationMenu({Key? key, required this.navigationShell})
      : super(key: key);

  @override
  _NavigationMenuState createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int nav_index = 0;

  void goToBranch(int value) {
    widget.navigationShell.goBranch(value,
        initialLocation: value == widget.navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            trailing: TextButton(
              onPressed: () {
                print("Logout");
              },
              child: Icon(
                Icons.logout,
              ),
            ),
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text("Dashboard"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.report),
                label: Text("Reports"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text("Users"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.newspaper),
                label: Text("News"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.edit_document),
                label: Text("Requests"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month),
                label: Text("Schedule"),
              ),
            ],
            selectedIndex: nav_index,
            onDestinationSelected: (value) {
              setState(() {
                nav_index = value;
              });
              goToBranch(value);
            },
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}
