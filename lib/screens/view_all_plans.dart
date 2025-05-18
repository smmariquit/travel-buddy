/// A screen that displays all travel plans with a toggle between personal and shared plans.
///
/// This screen uses a TabBar to switch between viewing personal travel plans and plans
/// shared by other users. It also provides a floating action button to create new plans.
/// The screen handles both loading states and error cases gracefully.

// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:firebase_auth/firebase_auth.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/screens/add_travel/add_travel_plan_page.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'package:travel_app/widgets/travel_plan_card.dart';

/// A widget that displays all travel plans in a tabbed interface.
///
/// The widget manages two lists of travel plans:
/// * Personal plans created by the current user
/// * Plans shared with the current user by other users
class ViewAllPlans extends StatefulWidget {
  const ViewAllPlans({super.key});

  @override
  State<ViewAllPlans> createState() => _ViewAllPlansState();
}

/// The state for the [ViewAllPlans] widget.
///
/// Manages the state of travel plans, loading states, and error handling.
/// Uses a [TabController] to switch between personal and shared plans.
class _ViewAllPlansState extends State<ViewAllPlans>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AppUserProvider _userProvider;
  late final TravelTrackerProvider _travelProvider;
  late final String _userId;
  bool _isLoading = true;
  List<Travel> _yourPlans = [];
  List<Travel> _sharedPlans = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeProviders();
    _fetchPlans();
  }

  /// Initializes the tab controller and gets the current user's ID.
  void _initializeControllers() {
    _tabController = TabController(length: 2, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  /// Initializes the providers needed for user and travel plan management.
  void _initializeProviders() {
    _userProvider = context.read<AppUserProvider>();
    _travelProvider = context.read<TravelTrackerProvider>();
  }

  /// Fetches both personal and shared travel plans from Firebase.
  ///
  /// Updates the state with the fetched plans or displays an error message
  /// if the fetch operation fails.
  Future<void> _fetchPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final yourPlans = await _travelProvider.getTravelPlans();
      final sharedPlans = await _travelProvider.getSharedTravelPlans().first;

      if (!mounted) return;

      setState(() {
        _yourPlans = yourPlans;
        _sharedPlans = sharedPlans.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load travel plans. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Handles the addition of a new travel plan to the appropriate list.
  ///
  /// If the plan belongs to the current user, it's added to [_yourPlans].
  /// Otherwise, it's added to [_sharedPlans].
  void _handleNewTravelPlan(Travel? newTravelPlan) {
    if (newTravelPlan == null) return;

    setState(() {
      if (newTravelPlan.uid == _userId) {
        if (!_yourPlans.any((plan) => plan.id == newTravelPlan.id)) {
          // Pag may nadagdag, magkakaroon ng isang plan na hindi match sa new travel plan.
          _yourPlans.add(newTravelPlan);
        }
      } else {
        if (!_sharedPlans.any((plan) => plan.id == newTravelPlan.id)) {
          _sharedPlans.add(newTravelPlan);
        }
      }
    });
  }

  /// Dispose of the tab controller
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final newTravelPlan = args is Travel ? args : null;

    if (newTravelPlan != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleNewTravelPlan(newTravelPlan),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('All Plans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Your Plans'), Tab(text: 'Shared Plans')],
        ),
      ),
      body: _buildBody(),
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTravelPlanPage()),
            ),
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Builds the main body of the screen based on the current state.
  ///
  /// Returns:
  /// * A loading indicator if [_isLoading] is true
  /// * An error message with retry button if [_errorMessage] is not null
  /// * A [TabBarView] with the lists of plans otherwise
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchPlans, child: const Text('Retry')),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _PlansList(
          plans: _yourPlans,
          emptyMessage: 'No travel plans available.',
        ),
        _PlansList(
          plans: _sharedPlans,
          emptyMessage: 'No shared travel plans.',
        ),
      ],
    );
  }
}

/// A widget that displays a list of travel plans or an empty state message.
///
/// This widget is used to display either personal or shared travel plans
/// in a scrollable list format.
class _PlansList extends StatelessWidget {
  /// The list of travel plans to display.
  final List<Travel> plans;

  /// The message to display when the list is empty.
  final String emptyMessage;

  const _PlansList({required this.plans, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        
        final travel = plans[index];
        print("${travel.name} ${travel.endDate}");
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TravelPlanCard(
            travelId: travel.id,
            uid: travel.uid,
            name: travel.name,
            startDate: travel.startDate ?? DateTime.now(),
            endDate: travel.endDate,
            image:
                travel.imageUrl?.isNotEmpty == true
                    ? travel.imageUrl!
                    : 'assets/sample_image.jpg',
            location: travel.location,
            createdOn: travel.createdOn,
          ),
        );
      },
    );
  }
}
