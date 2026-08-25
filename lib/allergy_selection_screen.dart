import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/premium_upgrade_widget.dart';
import 'services/revenue_cat_service.dart';

class AllergySelectionScreen extends StatefulWidget {
  final bool isPro;
  
  const AllergySelectionScreen({super.key, this.isPro = false});

  @override
  State<AllergySelectionScreen> createState() => _AllergySelectionScreenState();
}

class _AllergySelectionScreenState extends State<AllergySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, List<Map<String, String>>> _filteredCategories = {};
  bool _isSearching = false;

  final Map<String, List<Map<String, String>>> basicAllergenCategories = {
    'Food': [
      {'name': 'Peanuts', 'scientific': 'Arachis hypogaea'},
      {'name': 'Milk', 'scientific': 'Lactose'},
      {'name': 'Pecan', 'scientific': 'Carya illinoinensis'},
      {'name': 'Wheat', 'scientific': 'Triticum aestivum'},
      {'name': 'Soy', 'scientific': 'Glycine max'},
      {'name': 'Shrimp', 'scientific': 'Penaeidae'},
      {'name': 'Banana', 'scientific': 'Musa'},
      {'name': 'Celery', 'scientific': 'Apium graveolens'},
    ],

  };

  final Map<String, List<Map<String, String>>> proAllergenCategories = {
    'Nuts & Seeds': [
      {'name': 'Peanuts', 'scientific': 'Arachis hypogaea'},
      {'name': 'Almond', 'scientific': 'Prunus dulcis'},
      {'name': 'Cashew', 'scientific': 'Anacardium occidentale'},
      {'name': 'Hazelnut', 'scientific': 'Corylus avellana'},
      {'name': 'Pecan', 'scientific': 'Carya illinoinensis'},
      {'name': 'Walnut', 'scientific': 'Juglans regia'},
      {'name': 'Brazil Nut', 'scientific': 'Bertholletia excelsa'},
      {'name': 'Pistachio', 'scientific': 'Pistacia vera'},
      {'name': 'Macadamia', 'scientific': 'Macadamia integrifolia'},
      {'name': 'Pine Nut', 'scientific': 'Pinus pinea'},
      {'name': 'Coconut', 'scientific': 'Cocos nucifera'},
      {'name': 'Sesame', 'scientific': 'Sesamum indicum'},
      {'name': 'Chestnut', 'scientific': 'Castanea'},
    ],
    'Dairy Products': [
      {'name': 'Milk', 'scientific': 'Lactose'},
      {'name': 'Casein', 'scientific': 'Casein proteins'},
      {'name': 'Whey', 'scientific': 'Whey proteins'},
      {'name': 'Egg', 'scientific': 'Ovalbumin'},
    ],
    'Grains & Wheat': [
      {'name': 'Wheat', 'scientific': 'Triticum aestivum'},
      {'name': 'Gluten', 'scientific': 'Gluten proteins'},
      {'name': 'Corn', 'scientific': 'Zea mays'},
      {'name': 'Rice', 'scientific': 'Oryza sativa'},
      {'name': 'Oats', 'scientific': 'Avena sativa'},
      {'name': 'Barley', 'scientific': 'Hordeum vulgare'},
      {'name': 'Rye', 'scientific': 'Secale cereale'},
      {'name': 'Quinoa', 'scientific': 'Chenopodium quinoa'},
      {'name': 'Buckwheat', 'scientific': 'Fagopyrum esculentum'},
    ],
    'Legumes & Soy': [
      {'name': 'Soy', 'scientific': 'Glycine max'},
      {'name': 'Lupin', 'scientific': 'Lupinus'},
    ],
    'Seafood': [
      {'name': 'Fish', 'scientific': 'Various'},
      {'name': 'Shrimp', 'scientific': 'Penaeidae'},
      {'name': 'Crab', 'scientific': 'Brachyura'},
      {'name': 'Lobster', 'scientific': 'Homarus americanus'},
      {'name': 'Oysters', 'scientific': 'Ostreidae'},
      {'name': 'Mussels', 'scientific': 'Mytilidae'},
      {'name': 'Clams', 'scientific': 'Veneridae'},
      {'name': 'Scallops', 'scientific': 'Pectinidae'},
      {'name': 'Squid', 'scientific': 'Teuthida'},
      {'name': 'Octopus', 'scientific': 'Octopoda'},
      {'name': 'Anchovies', 'scientific': 'Engraulidae'},
      {'name': 'Tuna', 'scientific': 'Thunnus'},
      {'name': 'Salmon', 'scientific': 'Salmo'},
      {'name': 'Cod', 'scientific': 'Gadus'},
      {'name': 'Mackerel', 'scientific': 'Scombridae'},
      {'name': 'Sardines', 'scientific': 'Clupeidae'},
      {'name': 'Trout', 'scientific': 'Salmonidae'},
      {'name': 'Bass', 'scientific': 'Moronidae'},
      {'name': 'Snapper', 'scientific': 'Lutjanidae'},
      {'name': 'Grouper', 'scientific': 'Epinephelus'},
      {'name': 'Mahi Mahi', 'scientific': 'Coryphaena hippurus'},
      {'name': 'Halibut', 'scientific': 'Hippoglossus'},
      {'name': 'Flounder', 'scientific': 'Paralichthys'},
      {'name': 'Sole', 'scientific': 'Soleidae'},
      {'name': 'Perch', 'scientific': 'Percidae'},
      {'name': 'Catfish', 'scientific': 'Ictaluridae'},
      {'name': 'Tilapia', 'scientific': 'Cichlidae'},
      {'name': 'Sea Bass', 'scientific': 'Serranidae'},
      {'name': 'Red Snapper', 'scientific': 'Lutjanus campechanus'},
      {'name': 'Yellowfin Tuna', 'scientific': 'Thunnus albacares'},
      {'name': 'Albacore Tuna', 'scientific': 'Thunnus alalunga'},
      {'name': 'Skipjack Tuna', 'scientific': 'Katsuwonus pelamis'},
      {'name': 'Bluefin Tuna', 'scientific': 'Thunnus thynnus'},
      {'name': 'Atlantic Salmon', 'scientific': 'Salmo salar'},
      {'name': 'Pacific Salmon', 'scientific': 'Oncorhynchus'},
      {'name': 'Rainbow Trout', 'scientific': 'Oncorhynchus mykiss'},
      {'name': 'Brook Trout', 'scientific': 'Salvelinus fontinalis'},
      {'name': 'Brown Trout', 'scientific': 'Salmo trutta'},
      {'name': 'Lake Trout', 'scientific': 'Salvelinus namaycush'},
      {'name': 'Arctic Char', 'scientific': 'Salvelinus alpinus'},
      {'name': 'Whitefish', 'scientific': 'Coregonus'},
      {'name': 'Herring', 'scientific': 'Clupea'},
      {'name': 'Pike', 'scientific': 'Esox'},
      {'name': 'Walleye', 'scientific': 'Sander vitreus'},
      {'name': 'Bluefish', 'scientific': 'Pomatomus saltatrix'},
      {'name': 'Striped Bass', 'scientific': 'Morone saxatilis'},
      {'name': 'Rockfish', 'scientific': 'Sebastes'},
      {'name': 'Monkfish', 'scientific': 'Lophius'},
      {'name': 'Swordfish', 'scientific': 'Xiphias gladius'},
      {'name': 'Marlin', 'scientific': 'Istiophoridae'},
      {'name': 'Shark', 'scientific': 'Selachimorpha'},
      {'name': 'Ray', 'scientific': 'Batoidea'},
      {'name': 'Eel', 'scientific': 'Anguilliformes'},
      {'name': 'Sea Urchin', 'scientific': 'Echinoidea'},
      {'name': 'Abalone', 'scientific': 'Haliotis'},
      {'name': 'Conch', 'scientific': 'Strombidae'},
      {'name': 'Whelk', 'scientific': 'Buccinidae'},
      {'name': 'Cockles', 'scientific': 'Cardiidae'},
      {'name': 'Razor Clams', 'scientific': 'Solenidae'},
      {'name': 'Geoduck', 'scientific': 'Panopea generosa'},
      {'name': 'Surf Clams', 'scientific': 'Mactridae'},
      {'name': 'Quahog', 'scientific': 'Mercenaria mercenaria'},
      {'name': 'Littleneck Clams', 'scientific': 'Protothaca staminea'},
      {'name': 'Cherrystone Clams', 'scientific': 'Mercenaria mercenaria'},
      {'name': 'Topneck Clams', 'scientific': 'Mercenaria mercenaria'},
      {'name': 'Chowder Clams', 'scientific': 'Mercenaria mercenaria'},
      {'name': 'Manila Clams', 'scientific': 'Venerupis philippinarum'},
      {'name': 'Pacific Oysters', 'scientific': 'Crassostrea gigas'},
      {'name': 'Eastern Oysters', 'scientific': 'Crassostrea virginica'},
      {'name': 'Kumamoto Oysters', 'scientific': 'Crassostrea sikamea'},
      {'name': 'Olympia Oysters', 'scientific': 'Ostrea lurida'},
      {'name': 'European Flat Oysters', 'scientific': 'Ostrea edulis'},
      {'name': 'Blue Mussels', 'scientific': 'Mytilus edulis'},
      {'name': 'Green Mussels', 'scientific': 'Perna viridis'},
      {'name': 'Mediterranean Mussels', 'scientific': 'Mytilus galloprovincialis'},
      {'name': 'New Zealand Mussels', 'scientific': 'Perna canaliculus'},
      {'name': 'Bay Scallops', 'scientific': 'Argopecten irradians'},
      {'name': 'Sea Scallops', 'scientific': 'Placopecten magellanicus'},
      {'name': 'Calico Scallops', 'scientific': 'Argopecten gibbus'},
      {'name': 'Weathervane Scallops', 'scientific': 'Patinopecten caurinus'},
      {'name': 'Pink Shrimp', 'scientific': 'Farfantepenaeus duorarum'},
      {'name': 'White Shrimp', 'scientific': 'Litopenaeus setiferus'},
      {'name': 'Brown Shrimp', 'scientific': 'Farfantepenaeus aztecus'},
      {'name': 'Rock Shrimp', 'scientific': 'Sicyonia brevirostris'},
      {'name': 'Spot Shrimp', 'scientific': 'Pandalus platyceros'},
      {'name': 'Royal Red Shrimp', 'scientific': 'Pleoticus robustus'},
      {'name': 'Tiger Shrimp', 'scientific': 'Penaeus monodon'},
      {'name': 'Black Tiger Shrimp', 'scientific': 'Penaeus monodon'},
      {'name': 'Vannamei Shrimp', 'scientific': 'Litopenaeus vannamei'},
      {'name': 'Blue Crab', 'scientific': 'Callinectes sapidus'},
      {'name': 'Dungeness Crab', 'scientific': 'Metacarcinus magister'},
      {'name': 'Snow Crab', 'scientific': 'Chionoecetes opilio'},
      {'name': 'King Crab', 'scientific': 'Paralithodes camtschaticus'},
      {'name': 'Stone Crab', 'scientific': 'Menippe mercenaria'},
      {'name': 'Jonah Crab', 'scientific': 'Cancer borealis'},
      {'name': 'Rock Crab', 'scientific': 'Cancer irroratus'},
      {'name': 'Spider Crab', 'scientific': 'Libinia'},
      {'name': 'Horseshoe Crab', 'scientific': 'Limulidae'},
      {'name': 'Maine Lobster', 'scientific': 'Homarus americanus'},
      {'name': 'Spiny Lobster', 'scientific': 'Panulirus argus'},
      {'name': 'Slipper Lobster', 'scientific': 'Scyllaridae'},
      {'name': 'Australian Lobster', 'scientific': 'Panulirus cygnus'},
      {'name': 'Caribbean Spiny Lobster', 'scientific': 'Panulirus argus'},
      {'name': 'California Spiny Lobster', 'scientific': 'Panulirus interruptus'},
      {'name': 'Cuttlefish', 'scientific': 'Sepiida'},
      {'name': 'Nautilus', 'scientific': 'Nautilidae'},
      {'name': 'Ammonite', 'scientific': 'Ammonoidea'},
      {'name': 'Belemnite', 'scientific': 'Belemnoidea'},
      {'name': 'Crinoid', 'scientific': 'Crinoidea'},
      {'name': 'Brachiopod', 'scientific': 'Brachiopoda'},
      {'name': 'Bryozoan', 'scientific': 'Bryozoa'},
      {'name': 'Coral', 'scientific': 'Anthozoa'},
      {'name': 'Jellyfish', 'scientific': 'Scyphozoa'},
      {'name': 'Sea Anemone', 'scientific': 'Actiniaria'},
      {'name': 'Sea Cucumber', 'scientific': 'Holothuroidea'},
      {'name': 'Sea Star', 'scientific': 'Asteroidea'},
      {'name': 'Brittle Star', 'scientific': 'Ophiuroidea'},
      {'name': 'Sand Dollar', 'scientific': 'Clypeasteroida'},
      {'name': 'Periwinkle', 'scientific': 'Littorinidae'},
      {'name': 'Limpet', 'scientific': 'Patellidae'},
      {'name': 'Chiton', 'scientific': 'Polyplacophora'},
    ],
    'Fruits & Vegetables': [
      {'name': 'Kiwi', 'scientific': 'Actinidia deliciosa'},
      {'name': 'Banana', 'scientific': 'Musa'},
      {'name': 'Tomato', 'scientific': 'Solanum lycopersicum'},
      {'name': 'Celery', 'scientific': 'Apium graveolens'},
      {'name': 'Strawberry', 'scientific': 'Fragaria × ananassa'},
      {'name': 'Apple', 'scientific': 'Malus domestica'},
      {'name': 'Peach', 'scientific': 'Prunus persica'},
      {'name': 'Pear', 'scientific': 'Pyrus'},
      {'name': 'Melon', 'scientific': 'Cucumis melo'},
      {'name': 'Cherry', 'scientific': 'Prunus avium'},
      {'name': 'Plum', 'scientific': 'Prunus domestica'},
      {'name': 'Apricot', 'scientific': 'Prunus armeniaca'},
      {'name': 'Grapes', 'scientific': 'Vitis vinifera'},
      {'name': 'Orange', 'scientific': 'Citrus × sinensis'},
      {'name': 'Lemon', 'scientific': 'Citrus limon'},
      {'name': 'Lime', 'scientific': 'Citrus aurantiifolia'},
      {'name': 'Mandarin', 'scientific': 'Citrus reticulata'},
      {'name': 'Mango', 'scientific': 'Mangifera indica'},
      {'name': 'Avocado', 'scientific': 'Persea americana'},
      {'name': 'Carrot', 'scientific': 'Daucus carota'},
      {'name': 'Potato', 'scientific': 'Solanum tuberosum'},
      {'name': 'Sweet Potato', 'scientific': 'Ipomoea batatas'},
      {'name': 'Capsicum', 'scientific': 'Capsicum annuum'},
      {'name': 'Chilli', 'scientific': 'Capsicum frutescens'},
      {'name': 'Cucumber', 'scientific': 'Cucumis sativus'},
      {'name': 'Zucchini', 'scientific': 'Cucurbita pepo'},
      {'name': 'Peas', 'scientific': 'Pisum sativum'},
      {'name': 'Lentils', 'scientific': 'Lens culinaris'},
      {'name': 'Chickpeas', 'scientific': 'Cicer arietinum'},
      {'name': 'Spinach', 'scientific': 'Spinacia oleracea'},
      {'name': 'Lettuce', 'scientific': 'Lactuca sativa'},
    ],







  };

  // Scientific names mapping
  final Map<String, String> scientificNames = {
    // Common Food Allergens
    'Milk': 'Lactose',
    'Peanuts': 'Arachis hypogaea',
    'Tree Nuts': 'Various',
    'Wheat': 'Triticum aestivum',
    'Soy': 'Glycine max',
    'Shrimp': 'Penaeidae',
    'Fish': 'Various',
    'Shellfish': 'Crustacea',
    'Sesame': 'Sesamum indicum',
    'Mustard': 'Sinapis alba',
    

    

    
    // Detailed Food Allergens
    'Almond': 'Prunus dulcis',
    'Cashew': 'Anacardium occidentale',
    'Hazelnut': 'Corylus avellana',
    'Pecan': 'Carya illinoinensis',
    'Walnut': 'Juglans regia',
    'Brazil Nut': 'Bertholletia excelsa',
    'Pistachio': 'Pistacia vera',
    'Macadamia': 'Macadamia integrifolia',
    'Pine Nut': 'Pinus pinea',
    'Coconut': 'Cocos nucifera',
    'Chestnut': 'Castanea',
    'Gluten': 'Gluten proteins',
    'Lactose': 'Lactose',
    'Casein': 'Casein proteins',
    'Whey': 'Whey proteins',
    'Corn': 'Zea mays',
    'Rice': 'Oryza sativa',
    'Oats': 'Avena sativa',
    'Barley': 'Hordeum vulgare',
    'Rye': 'Secale cereale',
    'Quinoa': 'Chenopodium quinoa',
    'Buckwheat': 'Fagopyrum esculentum',
    // Fruits & Vegetables
    'Apple': 'Malus domestica',
    'Peach': 'Prunus persica',
    'Pear': 'Pyrus',
    'Melon': 'Cucumis melo',
    'Cherry': 'Prunus avium',
    'Plum': 'Prunus domestica',
    'Apricot': 'Prunus armeniaca',
    'Grapes': 'Vitis vinifera',
    'Orange': 'Citrus × sinensis',
    'Lemon': 'Citrus limon',
    'Lime': 'Citrus aurantiifolia',
    'Mandarin': 'Citrus reticulata',
    'Mango': 'Mangifera indica',
    'Avocado': 'Persea americana',
    'Carrot': 'Daucus carota',
    'Potato': 'Solanum tuberosum',
    'Sweet Potato': 'Ipomoea batatas',
    'Capsicum': 'Capsicum annuum',
    'Chilli': 'Capsicum frutescens',
    'Cucumber': 'Cucumis sativus',
    'Zucchini': 'Cucurbita pepo',
    'Peas': 'Pisum sativum',
    'Lentils': 'Lens culinaris',
    'Chickpeas': 'Cicer arietinum',
    'Spinach': 'Spinacia oleracea',
    'Lettuce': 'Lactuca sativa',
    

    

    

    

  };

  final Map<String, String> selectedAllergies = {};
  final Map<String, String> allergySeverities = {};
  bool isLoading = true;
  final Map<String, bool> newlySelectedAllergies = {}; // Track newly selected allergies
  final Map<String, bool> savedAllergies = {}; // Track which allergies are actually saved
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAllergies();
    _loadPremiumStatus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredCategories = _filterCategories(query);
      } else {
        _filteredCategories = {};
      }
    });
  }

  Map<String, List<Map<String, String>>> _filterCategories(String query) {
    final categories = widget.isPro ? proAllergenCategories : basicAllergenCategories;
    final filtered = <String, List<Map<String, String>>>{};
    
    for (final entry in categories.entries) {
      final categoryName = entry.key;
      final allergens = entry.value;
      final filteredAllergens = allergens.where((allergen) {
        final name = allergen['name']!.toLowerCase();
        final scientific = allergen['scientific']!.toLowerCase();
        return name.contains(query) || scientific.contains(query);
      }).toList();
      
      if (filteredAllergens.isNotEmpty) {
        filtered[categoryName] = filteredAllergens;
      }
    }
    
    return filtered;
  }

  void _scrollToAllergen(String allergenName) {
    // Find the allergen in the list and scroll to it
    final categories = widget.isPro ? proAllergenCategories : basicAllergenCategories;
    double offset = 0;
    bool found = false;
    
    for (final entry in categories.entries) {
      final allergens = entry.value;
      for (final allergen in allergens) {
        if (allergen['name']!.toLowerCase().contains(_searchController.text.toLowerCase())) {
          found = true;
          break;
        }
        offset += 80; // Approximate height per allergen item
      }
      if (found) break;
      offset += 60; // Approximate height for category header
    }
    
    if (found && _scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadSavedAllergies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allergiesJson = prefs.getStringList('saved_allergies') ?? [];
      
      if (allergiesJson.isNotEmpty) {
        final savedAllergiesList = allergiesJson
            .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
            .toList();
        
        setState(() {
          for (var allergy in savedAllergiesList) {
            selectedAllergies[allergy['name']] = allergy['severity'] ?? 'Medium';
            allergySeverities[allergy['name']] = allergy['severity'] ?? 'Medium';
            savedAllergies[allergy['name']] = true; // Mark as actually saved
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAllergies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allergiesList = selectedAllergies.entries.map((entry) {
        return {
          'name': entry.key,
          'severity': entry.value,
          'category': _getCategoryForAllergen(entry.key),
          'lastReaction': DateTime.now().toString().split(' ')[0],
          'notes': '',
        };
      }).toList();

      final allergiesJson = allergiesList
          .map((allergy) => jsonEncode(allergy))
          .toList();
      
      await prefs.setStringList('saved_allergies', allergiesJson);
      
      // Mark all selected allergies as saved
      setState(() {
        for (var entry in selectedAllergies.entries) {
          savedAllergies[entry.key] = true;
        }
        newlySelectedAllergies.clear();
      });
    } catch (e) {
      // Handle error
    }
  }

  String _getCategoryForAllergen(String allergenName) {
    // For premium users, search in the organized categories
    // For basic users, search in basic categories
    final categories = widget.isPro 
        ? proAllergenCategories
        : basicAllergenCategories;
        
    for (var category in categories.entries) {
      if (category.value.any((allergen) => allergen['name'] == allergenName)) {
        return category.key;
      }
    }
    return 'Other';
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await RevenueCatService.hasPremiumAccess();
    setState(() {
      _isPremium = isPremium;
    });
  }

  @override
  Widget build(BuildContext context) {
    // For premium users, show the full organized allergen categories
    // For basic users, show simplified categories with basic allergens only
    final categories = _isSearching 
        ? _filteredCategories
        : (widget.isPro 
            ? proAllergenCategories  // Full organized categories for premium
            : basicAllergenCategories); // Basic categories only
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Select Your Allergies',
            style: GoogleFonts.nunito(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFF4A9E9C)),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4A9E9C),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Select Your Allergies',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF4A9E9C)),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            
            // Search Box
            if (widget.isPro)
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search allergens...',
                    hintStyle: GoogleFonts.nunito(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _scrollToAllergen(value);
                    }
                  },
                ),
              ),
            
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (var category in categories.entries) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              category.key,
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ...category.value.map((allergen) {
                            final isSaved = savedAllergies.containsKey(allergen['name']);
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                  ),
                                ),
                                color: isSaved ? const Color(0xFF4A9E9C).withValues(alpha: 0.05) : null,
                              ),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          allergen['name']!,
                                          style: GoogleFonts.nunito(
                                                  color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (widget.isPro && scientificNames.containsKey(allergen['name']))
                                          Text(
                                            scientificNames[allergen['name']!]!,
                                            style: GoogleFonts.nunito(
                                                    color: Colors.grey,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSaved)
                                          Text(
                                            'SAVED',
                                            style: GoogleFonts.nunito(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                    value: selectedAllergies.containsKey(allergen['name']),
                                    activeColor: const Color(0xFF4A9E9C),
                                    checkColor: Colors.white,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedAllergies[allergen['name']!] = 'Medium';
                                          // Mark as newly selected if not already saved
                                          if (!allergySeverities.containsKey(allergen['name'])) {
                                            newlySelectedAllergies[allergen['name']!] = true;
                                          }
                                        } else {
                                          selectedAllergies.remove(allergen['name']);
                                          allergySeverities.remove(allergen['name']);
                                          newlySelectedAllergies.remove(allergen['name']);
                                          
                                          // If this was a saved allergy, remove it from saved storage
                                          if (isSaved) {
                                            _removeFromSavedAllergies(allergen['name']!);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  if (selectedAllergies.containsKey(allergen['name']) && newlySelectedAllergies.containsKey(allergen['name']))
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                      child: Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: DropdownButtonFormField<String>(
                                              value: selectedAllergies[allergen['name']],
                                              decoration: InputDecoration(
                                                labelText: 'Severity',
                                                labelStyle: GoogleFonts.nunito(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                              dropdownColor: Colors.white,
                                              style: GoogleFonts.nunito(
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                              selectedItemBuilder: (context) {
                                                return ['Low', 'Medium', 'High'].map((severity) {
                                                  return Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: _outlinedSeverityText(
                                                      severity,
                                                      fillColor: _severityColor(severity),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  );
                                                }).toList();
                                              },
                                              items: ['Low', 'Medium', 'High'].map((severity) {
                                                return DropdownMenuItem(
                                                  value: severity,
                                                  child: _outlinedSeverityText(
                                                    severity,
                                                    fillColor: _severityColor(severity),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (String? value) {
                                                if (value != null) {
                                                  setState(() {
                                                    selectedAllergies[allergen['name']!] = value;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  
                  // No results found message
                  if (_isSearching && categories.isEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No allergens found',
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Premium upgrade section for non-premium users
                  if (!_isPremium) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.withValues(alpha: 0.1), Colors.amber.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unlock Premium Allergens',
                                        style: GoogleFonts.nunito(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Access 100+ additional allergens!',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 450,
                                        maxHeight: 700,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Text(
                                              'Upgrade to Premium',
                                              style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: const PremiumUpgradeWidget(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text(
                                                    'Maybe Later',
                                                    style: GoogleFonts.nunito(
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.star, color: Colors.white),
                              label: Text(
                                'Upgrade to Premium',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            // Save allergies to SharedPreferences
            await _saveAllergies();
            
            // Convert selected allergies to the format expected by MyAllergiesScreen
            final List<Map<String, dynamic>> selectedAllergiesList = selectedAllergies.entries.map((entry) {
              return {
                'name': entry.key,
                'severity': entry.value,
                'category': _getCategoryForAllergen(entry.key),
                'lastReaction': DateTime.now().toString().split(' ')[0], // Today's date
                'notes': '', // Empty notes by default
              };
            }).toList();

            if (!context.mounted) return;

            Navigator.pop(context, selectedAllergiesList);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A9E9C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Save',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Low':
        return Colors.yellow[700]!;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _outlinedSeverityText(
    String text, {
    required Color fillColor,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final baseStyle = GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
    return Stack(
      children: [
        Text(
          text,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: baseStyle.copyWith(color: fillColor),
        ),
      ],
    );
  }

  Future<void> _removeFromSavedAllergies(String allergenName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allergiesJson = prefs.getStringList('saved_allergies') ?? [];
      
      final updatedAllergies = allergiesJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .where((allergy) => allergy['name'] != allergenName)
          .map((allergy) => jsonEncode(allergy))
          .toList();
      
      await prefs.setStringList('saved_allergies', updatedAllergies);
      
      // Remove from savedAllergies map
      setState(() {
        savedAllergies.remove(allergenName);
      });
    } catch (e) {
      // Handle error
    }
  }


} 