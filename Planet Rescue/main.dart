import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      builder: (context, _) => const PlanetRescueApp(),
    ),
  );
}

class Planet {
  final String name;
  final String imageUrl;
  final List<String> tasks;
  const Planet(this.name, this.imageUrl, this.tasks);
}

enum BadgeCategory { tasks, planets }

class Badge {
  final String name;
  final String description;
  final IconData icon;
  final int threshold;
  final BadgeCategory category;
  Badge(this.name, this.description, this.icon, this.threshold, this.category);
}

class AppState extends ChangeNotifier {
  bool isDarkMode = false;
  bool isHighContrast = false;
  String username = "";
  String email = "";
  String password = "";
  String avatar = "https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg";
  bool isLoggedIn = false;
  int currentPlanetIndex = 0;
  final Map<String, int> taskCounts = {};
  double fontSize = 16.0;

  // Track unlocked badges to prevent duplicate pop-ups
  final Set<String> _unlockedBadgeNames = {};

  // Stream to broadcast badge unlock events to the UI layer
  final StreamController<Badge> _badgeUnlockController = StreamController<Badge>.broadcast();
  Stream<Badge> get badgeUnlockStream => _badgeUnlockController.stream;

  final List<Planet> planets = const [
    Planet("Mission 1: Landlock", "https://storage.googleapis.com/gen-studio-assets/flutter-gen-ui/planet_bg.png", ["Plant a tree", "Recycle 5 things", "Participate in a park clean-up event", "Volunteer for a local weed pull", "Stop using paper reciepts for 3 days", "Convert a portion of a lawn or balcony into a native wildflower garden", "Switch to 100% organic fertilizers for 1 week", "Install or build a birdhouse near your home", "Use a digital notebook or go entirely paperless for school or work for 10 days", "Switch to certified FSC (Forest Stewardship Council) wood"]),
    Planet("Mission 2: Watercountry", "https://storage.googleapis.com/gen-studio-assets/flutter-gen-ui/planet_bg.png", ["Take a shower in under 5 minutes", "Turn off the faucet when brushing", "Pick up 3 pieces of trash in a local body of water", "Collect warming shower water and use it to water plants", "Clear debris from your street's storm drain", "Switch to biodegradable and phosphate-free laundry and dish detergents", "Fix any leaking faucet or toilet in your home immediately", "Switch to metal or bamboo straws instead of using plastic ones", "Only run the dishwasher or washing machine when you have a completely full load", "Set up a rain barrel to collect water for your garden", "Stop flushing wet wipes, medications, or chemicals down the toilet", "Use reef-safe sunscreen when swimming in natural bodies of water", "Choose sustainably sourced seafood certified by the MSC (Marine Stewardship Council)", "Wash your car on the lawn instead of the driveway so the grass filters the soapy runoff", "Dispose of cooking oil in the trash instead of pouring it down the drain"]),
    Planet("Mission 3: Populus", "https://storage.googleapis.com/gen-studio-assets/flutter-gen-ui/planet_bg.png", ["Pick up 10 pieces of litter", "Switch to disposable water bottle", "Use an air purifier for 3 days", "Wear a mask for 1 week", "Eat 100% plant-based meals for 10 days", "Walk, bike, or take public transit to work or school for an entire week", "Wash all laundry loads on the 'cold water' setting", "Purchase 50% of your weekly groceries from a local farmers' market or CSA loop for 1 month", "Hang-dry your clothes on a drying rack or clothesline instead of using the dryer", "Buy pantry staples in bulk using your own reusable containers", "Delete unneeded cloud storage files and emails to reduce data center power demands", "Write an email or letter to a local politician demanding better public recycling or transit", "Carpool with someone for an event", "Dedicate one weekend to completely zero-driving activities", "Transform a piece of trash into a functional household tool", "Collect all dead batteries, old phones, and cords and take them to a certified e-waste hub", "Buy your next clothing item or piece of furniture completely secondhand or thrifted", "Carry a reusable bag to every shopping trip", "Unplug electronics when not in use", "Eat all your leftovers before they spoil", "Cook meals at home to reduce packaging waste from takeout containers", "Combine multiple errands into a single driving trip to minimize fuel usage", "Use rechargeable batteries for household remotes, controllers, and toys", "Support an ethical eco-business by leaving a positive reviews or buying 1 of their products", "Choose a digital gift over a physical item"]),
  ];

  final List<Badge> allBadges = [
    Badge("Eco-Friendly", "Complete 5 tasks", Icons.eco, 5, BadgeCategory.tasks),
    Badge("Environment Supporter", "Complete 15 tasks", Icons.eco, 15, BadgeCategory.tasks),
    Badge("Nature Activist", "Complete 50 tasks", Icons.eco, 50, BadgeCategory.tasks),
    Badge("Rookie Planet Helper", "Save 1 planet", Icons.public, 1, BadgeCategory.planets),
    Badge("Pro Planet Saver", "Save 3 planets", Icons.public, 3, BadgeCategory.planets),
  ];

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void toggleHighContrast() {
    isHighContrast = !isHighContrast;
    notifyListeners();
  }

  void login(String name, String userEmail, String pass) {
    username = name;
    email = userEmail;
    password = pass;
    isLoggedIn = true;
    notifyListeners();
  }

  void updateTask(String task, bool done) {
    taskCounts[task] = (taskCounts[task] ?? 0) + (done ? 1 : -1);
    notifyListeners();
    _checkForNewBadges();
  }

  int get totalCompleted => taskCounts.values.fold(0, (a, b) => a + b);

  void setFontSize(double size) {
    fontSize = size;
    notifyListeners();
  }

  void nextPlanet() {
    currentPlanetIndex = (currentPlanetIndex + 1) % planets.length;
    notifyListeners();
  }

  void _checkForNewBadges() {
    int completedPlanetsCount = 0;
    
    // Evaluate full completion for each planet dynamically
    for (var planet in planets) {
      bool allTasksDone = true;
      for (var task in planet.tasks) {
        if ((taskCounts[task] ?? 0) <= 0) {
          allTasksDone = false;
          break;
        }
      }
      if (allTasksDone) {
        completedPlanetsCount++;
      }
    }

    for (var badge in allBadges) {
      bool qualifies = false;
      
      if (badge.category == BadgeCategory.tasks) {
        qualifies = totalCompleted >= badge.threshold;
      } else if (badge.category == BadgeCategory.planets) {
        qualifies = completedPlanetsCount >= badge.threshold;
      }

      if (qualifies && !_unlockedBadgeNames.contains(badge.name)) {
        _unlockedBadgeNames.add(badge.name);
        _badgeUnlockController.add(badge);
      }
    }
  }

  @override
  void dispose() {
    _badgeUnlockController.close();
    super.dispose();
  }
}

class PlanetRescueApp extends StatelessWidget {
  const PlanetRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: state.isHighContrast ? Colors.yellow : Colors.teal,
          brightness: state.isDarkMode ? Brightness.dark : Brightness.light,
          contrastLevel: state.isHighContrast ? 1.0 : 0.0,
        ),
      ),
      home: state.isLoggedIn ? const MainScreen() : const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, size: 100, color: Colors.teal),
              const SizedBox(height: 24),
              Text("Planet Rescue", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              TextField(controller: _name, decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 16),
              TextField(controller: _email, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () => Provider.of<AppState>(context, listen: false).login(_name.text, _email.text, _pass.text), child: const Text("LOGIN / SIGN UP")))
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  StreamSubscription<Badge>? _badgeSubscription;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    _badgeSubscription = state.badgeUnlockStream.listen((newBadge) {
      _showBadgeDialog(newBadge);
    });
  }

  @override
  void dispose() {
    _badgeSubscription?.cancel();
    super.dispose();
  }

  void _showBadgeDialog(Badge badge) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("🏆 Badge Unlocked!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badge.icon, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              Text(badge.name, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(badge.description, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Awesome!"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: Row(children: [CircleAvatar(backgroundImage: NetworkImage(state.avatar)), const SizedBox(width: 12), Text(state.username)])),
      body: Padding(padding: const EdgeInsets.all(16.0), child: [const PlanetsPage(), const TasksPage(), const BadgesPage(), const SettingsPage()][_idx]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.public), label: "Planet"),
          NavigationDestination(icon: Icon(Icons.list_alt), label: "Tasks"),
          NavigationDestination(icon: Icon(Icons.star), label: "Badges"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

class PlanetsPage extends StatelessWidget {
  const PlanetsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final planet = state.planets[state.currentPlanetIndex];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(planet.imageUrl), fit: BoxFit.cover)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(planet.name, style: TextStyle(fontSize: 32 * state.fontSize / 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Text("Commander ${state.username}, ready for duty.", style: TextStyle(fontSize: 18 * state.fontSize / 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: state.planets[state.currentPlanetIndex].tasks.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final t = state.planets[state.currentPlanetIndex].tasks[i];
              final val = state.taskCounts[t] ?? 0;
              return Card(child: CheckboxListTile(title: Text(t), value: val > 0, onChanged: (v) => state.updateTask(t, v!)));
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => state.nextPlanet(), child: const Text("Next Planet")))
      ],
    );
  }
}

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});
  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final filtered = state.allBadges.where((b) => b.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: [
        TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(labelText: "Search Badges", prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              Text("Tasks Badges", style: Theme.of(context).textTheme.titleLarge),
              ..._buildBadgeList(filtered.where((b) => b.category == BadgeCategory.tasks).toList(), state),
              const Divider(height: 32),
              Text("Planet Badges", style: Theme.of(context).textTheme.titleLarge),
              ..._buildBadgeList(filtered.where((b) => b.category == BadgeCategory.planets).toList(), state),
            ],
          ),
        )
      ],
    );
  }

  List<Widget> _buildBadgeList(List<Badge> badges, AppState state) {
    return badges.map<Widget>((b) {
      bool earned = false;
      
      if (b.category == BadgeCategory.tasks) {
        earned = state.totalCompleted >= b.threshold;
      } else if (b.category == BadgeCategory.planets) {
        int completedPlanets = 0;
        for (var planet in state.planets) {
          if (planet.tasks.every((t) => (state.taskCounts[t] ?? 0) > 0)) {
            completedPlanets++;
          }
        }
        earned = completedPlanets >= b.threshold;
      }

      return ListTile(
          leading: Icon(b.icon, color: earned ? Colors.amber : Colors.grey),
          title: Text(b.name),
          subtitle: Text(b.description),
          trailing: Icon(earned ? Icons.check_circle : Icons.circle_outlined));
    }).toList();
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return ListView(
      children: [
        SwitchListTile(title: const Text("Dark Theme"), value: state.isDarkMode, onChanged: (_) => state.toggleTheme(), secondary: const Icon(Icons.dark_mode)),
        SwitchListTile(title: const Text("High Contrast"), value: state.isHighContrast, onChanged: (_) => state.toggleHighContrast(), secondary: const Icon(Icons.contrast)),
        const Divider(),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("Font Size: ${state.fontSize.toInt()}")),
        Slider(value: state.fontSize, min: 12, max: 24, onChanged: (v) => state.setFontSize(v)),
      ],
    );
  }
}
