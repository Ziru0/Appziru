import 'package:flutter/material.dart';
import '../tabpages/services_tab.dart';
import '../tabpages/home_tab.dart';
import '../tabpages/profile_tab.dart';
import '../tabpages/activity_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _State();
}


class _State extends State<HomeScreen> with SingleTickerProviderStateMixin
{
  TabController? tabController;
  int selectedIndex = 0;


  onItemClicked(int index)
  {
    setState(() {
      selectedIndex = index;
      tabController!.index = selectedIndex;
    });
  }

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: tabController,
        children: const [
          HomeTabPage(),
          ServicesTabPage(),
          ActivityTabPage(),
          ProfileTabPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label:  "Home" ,
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label:  "Services" ,
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label:  "Activity" ,
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label:  "Account" ,
          ),
        ],
        unselectedItemColor: Colors.white54,
        selectedItemColor: Colors.white,
        backgroundColor: Color(0xFF181C14),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 14),
        showUnselectedLabels: true,
        currentIndex: selectedIndex,
        onTap: onItemClicked,
      ),
    );
  }



}
