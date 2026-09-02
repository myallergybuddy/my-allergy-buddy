
import 'package:flutter/foundation.dart';
import 'barcode_utils.dart';
import 'html_text_utils.dart';
import 'open_food_facts_service.dart';
import '../tree_nuts_grouping.dart';

class ProductDatabaseService {
  // Enhanced product database with comprehensive Australian products
  static final Map<String, Map<String, dynamic>> _productDatabase = {
    // Original test products
    '1234567890123': {
      'name': 'Chocolate Chip Cookies',
      'brand': 'Generic Brand',
      'ingredients': [
        'wheat flour',
        'sugar',
        'butter',
        'chocolate chips',
        'eggs',
        'vanilla extract',
        'salt',
        'baking soda'
      ],
      'allergens': ['wheat', 'dairy', 'eggs'],
      'image': 'https://example.com/cookie.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, dairy, eggs, nuts, soy'
    },
    '9876543210987': {
      'name': 'Peanut Butter Sandwich',
      'brand': 'School Lunch',
      'ingredients': [
        'bread',
        'peanut butter',
        'jelly',
        'wheat flour',
        'sugar',
        'salt'
      ],
      'allergens': ['wheat', 'peanuts'],
      'image': 'https://example.com/sandwich.jpg',
      'crossContamination': ['tree nuts'],
      'processingFacility': 'Facility processes: wheat, peanuts, tree nuts'
    },
    '4567891234567': {
      'name': 'Milk Chocolate Bar',
      'brand': 'Sweet Treats',
      'ingredients': [
        'milk chocolate',
        'sugar',
        'cocoa butter',
        'milk powder',
        'vanilla',
        'soy lecithin'
      ],
      'allergens': ['dairy', 'soy'],
      'image': 'https://example.com/chocolate.jpg',
      'crossContamination': ['nuts'],
      'processingFacility': 'Facility processes: dairy, soy, nuts'
    },
    '7891234567890': {
      'name': 'Gluten-Free Bread',
      'brand': 'Healthy Choice',
      'ingredients': [
        'rice flour',
        'tapioca starch',
        'eggs',
        'olive oil',
        'salt',
        'yeast'
      ],
      'allergens': ['eggs'],
      'image': 'https://example.com/bread.jpg',
      'crossContamination': ['wheat'],
      'processingFacility': 'Dedicated gluten-free facility'
    },
    '3216549873210': {
      'name': 'Almond Milk',
      'brand': 'Nutty Goodness',
      'ingredients': [
        'almonds',
        'water',
        'vitamin e',
        'calcium carbonate',
        'sea salt'
      ],
      'allergens': ['tree nuts'],
      'image': 'https://example.com/almond-milk.jpg',
      'crossContamination': ['peanuts'],
      'processingFacility': 'Facility processes: tree nuts, peanuts'
    },
    
    // Enhanced Australian products database
    '9300605000000': {
      'name': 'Arnott\'s Tim Tam Original',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'cocoa butter',
        'cocoa mass',
        'milk solids',
        'vegetable oil',
        'glucose syrup',
        'emulsifiers',
        'salt',
        'raising agents',
        'flavours'
      ],
      'allergens': ['wheat', 'milk'],
      'image': 'https://example.com/tim-tam.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, milk, nuts, soy'
    },
    '9300605000001': {
      'name': 'Vegemite',
      'brand': 'Bega',
      'ingredients': [
        'yeast extract',
        'salt',
        'malt extract',
        'vegetable extract',
        'niacin',
        'thiamine',
        'riboflavin',
        'folate'
      ],
      'allergens': ['gluten'],
      'image': 'https://example.com/vegemite.jpg',
      'crossContamination': ['celery'],
      'processingFacility': 'Facility processes: gluten, celery'
    },
    '9300605000002': {
      'name': 'Weet-Bix',
      'brand': 'Sanitarium',
      'ingredients': [
        'whole grain wheat',
        'sugar',
        'salt',
        'malt extract',
        'vitamins',
        'minerals'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/weet-bix.jpg',
      'crossContamination': ['nuts'],
      'processingFacility': 'Facility processes: wheat, nuts'
    },
    '9300605000003': {
      'name': 'Cadbury Dairy Milk Chocolate',
      'brand': 'Cadbury',
      'ingredients': [
        'milk',
        'sugar',
        'cocoa mass',
        'cocoa butter',
        'emulsifiers',
        'flavours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/cadbury.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: milk, nuts, soy'
    },
    '9300605000004': {
      'name': 'Kraft Peanut Butter',
      'brand': 'Kraft',
      'ingredients': [
        'peanuts',
        'vegetable oil',
        'sugar',
        'salt',
        'emulsifier'
      ],
      'allergens': ['peanuts'],
      'image': 'https://example.com/kraft-peanut-butter.jpg',
      'crossContamination': ['tree nuts'],
      'processingFacility': 'Facility processes: peanuts, tree nuts'
    },
    
    // Additional Australian products
    '9300605000005': {
      'name': 'Milo',
      'brand': 'Nestlé',
      'ingredients': [
        'malted barley',
        'milk powder',
        'sugar',
        'cocoa',
        'malt extract',
        'vitamins',
        'minerals'
      ],
      'allergens': ['milk', 'gluten'],
      'image': 'https://example.com/milo.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: milk, gluten, nuts, soy'
    },
    '9300605000006': {
      'name': 'Kellogg\'s Nutri-Grain',
      'brand': 'Kellogg\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'corn flour',
        'salt',
        'malt extract',
        'vitamins',
        'minerals'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/nutri-grain.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000007': {
      'name': 'Uncle Tobys Oats',
      'brand': 'Uncle Tobys',
      'ingredients': [
        'rolled oats',
        'vitamins',
        'minerals'
      ],
      'allergens': ['gluten'],
      'image': 'https://example.com/uncle-tobys-oats.jpg',
      'crossContamination': ['wheat', 'nuts'],
      'processingFacility': 'Facility processes: oats, wheat, nuts'
    },
    '9300605000008': {
      'name': 'Smith\'s Original Chips',
      'brand': 'Smith\'s',
      'ingredients': [
        'potatoes',
        'vegetable oil',
        'salt',
        'sugar',
        'dextrose',
        'flavours'
      ],
      'allergens': [],
      'image': 'https://example.com/smiths-chips.jpg',
      'crossContamination': ['milk', 'wheat'],
      'processingFacility': 'Facility processes: milk, wheat'
    },
    '9300605000009': {
      'name': 'Red Rock Deli Chips',
      'brand': 'Red Rock Deli',
      'ingredients': [
        'potatoes',
        'sunflower oil',
        'salt',
        'spices',
        'herbs',
        'natural flavours'
      ],
      'allergens': [],
      'image': 'https://example.com/red-rock-chips.jpg',
      'crossContamination': ['milk', 'wheat'],
      'processingFacility': 'Facility processes: milk, wheat'
    },
    '9300605000010': {
      'name': 'Kettle Chips Sea Salt',
      'brand': 'Kettle',
      'ingredients': [
        'potatoes',
        'sunflower oil',
        'sea salt'
      ],
      'allergens': [],
      'image': 'https://example.com/kettle-chips.jpg',
      'crossContamination': ['milk', 'wheat'],
      'processingFacility': 'Facility processes: milk, wheat'
    },
    '9300605000011': {
      'name': 'Arnott\'s Shapes Original',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'vegetable oil',
        'salt',
        'sugar',
        'malt extract',
        'flavours',
        'colours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/shapes.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000012': {
      'name': 'Arnott\'s Jatz',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'vegetable oil',
        'salt',
        'sugar',
        'malt extract',
        'yeast',
        'flavours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/jatz.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000013': {
      'name': 'Arnott\'s Sao',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'vegetable oil',
        'salt',
        'sugar',
        'malt extract',
        'yeast'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/sao.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000014': {
      'name': 'Arnott\'s Iced VoVo',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'vegetable oil',
        'coconut',
        'raspberry jam',
        'pink icing',
        'coconut',
        'flavours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/iced-vovo.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000015': {
      'name': 'Arnott\'s Monte Carlo',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'vegetable oil',
        'raspberry jam',
        'coconut',
        'flavours',
        'colours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/monte-carlo.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000016': {
      'name': 'Arnott\'s Scotch Finger',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'vegetable oil',
        'malt extract',
        'salt',
        'flavours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/scotch-finger.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000017': {
      'name': 'Arnott\'s Tiny Teddy',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'vegetable oil',
        'malt extract',
        'salt',
        'flavours',
        'colours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/tiny-teddy.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000018': {
      'name': 'Arnott\'s Choc Ripple',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'cocoa',
        'vegetable oil',
        'malt extract',
        'salt',
        'flavours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/choc-ripple.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000019': {
      'name': 'Arnott\'s Kingston',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'vegetable oil',
        'cocoa',
        'malt extract',
        'salt',
        'flavours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/kingston.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    '9300605000020': {
      'name': 'Arnott\'s Tic Toc',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'sugar',
        'vegetable oil',
        'malt extract',
        'salt',
        'flavours',
        'colours'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/tic-toc.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    
    // Dairy products
    '9300605000021': {
      'name': 'Bega Stringers',
      'brand': 'Bega',
      'ingredients': [
        'cheese',
        'milk',
        'salt',
        'enzymes',
        'colours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/bega-stringers.jpg',
      'crossContamination': ['soy'],
      'processingFacility': 'Facility processes: milk, soy'
    },
    '9300605000022': {
      'name': 'Coon Cheese',
      'brand': 'Coon',
      'ingredients': [
        'milk',
        'salt',
        'enzymes',
        'colours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/coon-cheese.jpg',
      'crossContamination': ['soy'],
      'processingFacility': 'Facility processes: milk, soy'
    },
    '9300605000023': {
      'name': 'Mainland Tasty Cheese',
      'brand': 'Mainland',
      'ingredients': [
        'milk',
        'salt',
        'enzymes',
        'colours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/mainland-tasty.jpg',
      'crossContamination': ['soy'],
      'processingFacility': 'Facility processes: milk, soy'
    },
    
    // Beverages
    '9300605000024': {
      'name': 'Bundaberg Ginger Beer',
      'brand': 'Bundaberg',
      'ingredients': [
        'water',
        'sugar',
        'ginger',
        'natural flavours',
        'preservatives'
      ],
      'allergens': [],
      'image': 'https://example.com/bundaberg-ginger-beer.jpg',
      'crossContamination': ['sulfites'],
      'processingFacility': 'Facility processes: sulfites'
    },
    '9300605000025': {
      'name': 'Golden Circle Pineapple Juice',
      'brand': 'Golden Circle',
      'ingredients': [
        'pineapple juice',
        'vitamin c'
      ],
      'allergens': [],
      'image': 'https://example.com/golden-circle-pineapple.jpg',
      'crossContamination': ['sulfites'],
      'processingFacility': 'Facility processes: sulfites'
    },
    
    // Confectionery
    '9300605000026': {
      'name': 'Allen\'s Snakes',
      'brand': 'Allen\'s',
      'ingredients': [
        'sugar',
        'glucose syrup',
        'gelatine',
        'colours',
        'flavours',
        'preservatives'
      ],
      'allergens': [],
      'image': 'https://example.com/allens-snakes.jpg',
      'crossContamination': ['milk', 'nuts'],
      'processingFacility': 'Facility processes: milk, nuts'
    },
    '9300605000027': {
      'name': 'Allen\'s Red Frogs',
      'brand': 'Allen\'s',
      'ingredients': [
        'sugar',
        'glucose syrup',
        'gelatine',
        'colours',
        'flavours',
        'preservatives'
      ],
      'allergens': [],
      'image': 'https://example.com/allens-red-frogs.jpg',
      'crossContamination': ['milk', 'nuts'],
      'processingFacility': 'Facility processes: milk, nuts'
    },
    '9300605000028': {
      'name': 'Allen\'s Minties',
      'brand': 'Allen\'s',
      'ingredients': [
        'sugar',
        'glucose syrup',
        'gelatine',
        'peppermint oil',
        'colours'
      ],
      'allergens': [],
      'image': 'https://example.com/allens-minties.jpg',
      'crossContamination': ['milk', 'nuts'],
      'processingFacility': 'Facility processes: milk, nuts'
    },
    
    // Spreads and condiments
    '9300605000029': {
      'name': 'Kraft Cheese Spread',
      'brand': 'Kraft',
      'ingredients': [
        'cheese',
        'milk',
        'water',
        'salt',
        'emulsifiers',
        'colours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/kraft-cheese-spread.jpg',
      'crossContamination': ['soy'],
      'processingFacility': 'Facility processes: milk, soy'
    },
    '9300605000030': {
      'name': 'MasterFoods Tomato Sauce',
      'brand': 'MasterFoods',
      'ingredients': [
        'tomato paste',
        'sugar',
        'vinegar',
        'salt',
        'spices',
        'flavours'
      ],
      'allergens': [],
      'image': 'https://example.com/masterfoods-tomato-sauce.jpg',
      'crossContamination': ['celery', 'sulfites'],
      'processingFacility': 'Facility processes: celery, sulfites'
    },
    
    // Breakfast cereals
    '9300605000031': {
      'name': 'Kellogg\'s Corn Flakes',
      'brand': 'Kellogg\'s',
      'ingredients': [
        'corn',
        'sugar',
        'salt',
        'malt extract',
        'vitamins',
        'minerals'
      ],
      'allergens': ['gluten'],
      'image': 'https://example.com/kelloggs-corn-flakes.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: gluten, nuts, soy'
    },
    '9300605000032': {
      'name': 'Kellogg\'s Rice Bubbles',
      'brand': 'Kellogg\'s',
      'ingredients': [
        'rice',
        'sugar',
        'salt',
        'malt extract',
        'vitamins',
        'minerals'
      ],
      'allergens': ['gluten'],
      'image': 'https://example.com/kelloggs-rice-bubbles.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: gluten, nuts, soy'
    },
    '9300605000033': {
      'name': 'Kellogg\'s Special K',
      'brand': 'Kellogg\'s',
      'ingredients': [
        'rice',
        'wheat gluten',
        'sugar',
        'salt',
        'malt extract',
        'vitamins',
        'minerals'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': 'https://example.com/kelloggs-special-k.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, nuts, soy'
    },
    
    // Snack foods
    '9300605000034': {
      'name': 'Twisties Cheese',
      'brand': 'Twisties',
      'ingredients': [
        'corn',
        'vegetable oil',
        'cheese powder',
        'salt',
        'flavours',
        'colours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/twisties-cheese.jpg',
      'crossContamination': ['wheat', 'nuts'],
      'processingFacility': 'Facility processes: milk, wheat, nuts'
    },
    '9300605000035': {
      'name': 'Twisties Chicken',
      'brand': 'Twisties',
      'ingredients': [
        'corn',
        'vegetable oil',
        'chicken powder',
        'salt',
        'flavours',
        'colours'
      ],
      'allergens': [],
      'image': 'https://example.com/twisties-chicken.jpg',
      'crossContamination': ['wheat', 'nuts', 'milk'],
      'processingFacility': 'Facility processes: wheat, nuts, milk'
    },
    
    // Baking products
    '9300605000036': {
      'name': 'CSR Caster Sugar',
      'brand': 'CSR',
      'ingredients': [
        'sugar'
      ],
      'allergens': [],
      'image': 'https://example.com/csr-caster-sugar.jpg',
      'crossContamination': [],
      'processingFacility': 'Dedicated sugar facility'
    },
    '9300605000037': {
      'name': 'CSR Brown Sugar',
      'brand': 'CSR',
      'ingredients': [
        'sugar',
        'molasses'
      ],
      'allergens': [],
      'image': 'https://example.com/csr-brown-sugar.jpg',
      'crossContamination': [],
      'processingFacility': 'Dedicated sugar facility'
    },
    
    // Canned goods
    '9300605000038': {
      'name': 'John West Tuna in Springwater',
      'brand': 'John West',
      'ingredients': [
        'tuna',
        'springwater',
        'salt'
      ],
      'allergens': ['fish'],
      'image': 'https://example.com/john-west-tuna.jpg',
      'crossContamination': [],
      'processingFacility': 'Dedicated fish facility'
    },
    '9300605000039': {
      'name': 'Sirena Tuna in Olive Oil',
      'brand': 'Sirena',
      'ingredients': [
        'tuna',
        'olive oil',
        'salt'
      ],
      'allergens': ['fish'],
      'image': 'https://example.com/sirena-tuna.jpg',
      'crossContamination': [],
      'processingFacility': 'Dedicated fish facility'
    },
    
    // Frozen foods
    '9300605000040': {
      'name': 'McCain Frozen Chips',
      'brand': 'McCain',
      'ingredients': [
        'potatoes',
        'vegetable oil',
        'salt'
      ],
      'allergens': [],
      'image': 'https://example.com/mccain-chips.jpg',
      'crossContamination': ['milk', 'wheat'],
      'processingFacility': 'Facility processes: milk, wheat'
    },
    
    // Additional real-world products for better testing
    '9300605000041': {
      'name': 'Nestlé Kit Kat',
      'brand': 'Nestlé',
      'ingredients': [
        'milk chocolate',
        'wheat flour',
        'sugar',
        'cocoa butter',
        'cocoa mass',
        'milk solids',
        'vegetable oil',
        'emulsifiers',
        'salt',
        'raising agents',
        'flavours'
      ],
      'allergens': ['wheat', 'milk'],
      'image': 'https://example.com/kit-kat.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, milk, nuts, soy'
    },
    '9300605000042': {
      'name': 'Mars Bar',
      'brand': 'Mars',
      'ingredients': [
        'milk chocolate',
        'sugar',
        'glucose syrup',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'vegetable oil',
        'emulsifiers',
        'salt',
        'flavours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/mars-bar.jpg',
      'crossContamination': ['nuts', 'soy', 'wheat'],
      'processingFacility': 'Facility processes: milk, nuts, soy, wheat'
    },
    '9300605000043': {
      'name': 'Snickers',
      'brand': 'Mars',
      'ingredients': [
        'milk chocolate',
        'peanuts',
        'sugar',
        'glucose syrup',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'vegetable oil',
        'emulsifiers',
        'salt',
        'flavours'
      ],
      'allergens': ['milk', 'peanuts'],
      'image': 'https://example.com/snickers.jpg',
      'crossContamination': ['tree nuts', 'soy', 'wheat'],
      'processingFacility': 'Facility processes: milk, peanuts, tree nuts, soy, wheat'
    },
    '9300605000044': {
      'name': 'Twix',
      'brand': 'Mars',
      'ingredients': [
        'milk chocolate',
        'wheat flour',
        'sugar',
        'glucose syrup',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'vegetable oil',
        'emulsifiers',
        'salt',
        'flavours'
      ],
      'allergens': ['wheat', 'milk'],
      'image': 'https://example.com/twix.jpg',
      'crossContamination': ['nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, milk, nuts, soy'
    },
    '9300605000045': {
      'name': 'M&M\'s Milk Chocolate',
      'brand': 'Mars',
      'ingredients': [
        'milk chocolate',
        'sugar',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'vegetable oil',
        'emulsifiers',
        'colours',
        'flavours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/mms.jpg',
      'crossContamination': ['nuts', 'soy', 'wheat'],
      'processingFacility': 'Facility processes: milk, nuts, soy, wheat'
    },
    '9300605000046': {
      'name': 'Doritos Nacho Cheese',
      'brand': 'PepsiCo',
      'ingredients': [
        'corn',
        'vegetable oil',
        'cheese powder',
        'salt',
        'spices',
        'flavours',
        'colours'
      ],
      'allergens': ['milk'],
      'image': 'https://example.com/doritos-nacho.jpg',
      'crossContamination': ['wheat', 'nuts', 'soy'],
      'processingFacility': 'Facility processes: milk, wheat, nuts, soy'
    },
    '9300605000047': {
      'name': 'Pringles Original',
      'brand': 'Kellogg\'s',
      'ingredients': [
        'potatoes',
        'vegetable oil',
        'wheat starch',
        'salt',
        'dextrose',
        'flavours'
      ],
      'allergens': ['wheat'],
      'image': 'https://example.com/pringles.jpg',
      'crossContamination': ['milk', 'nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, milk, nuts, soy'
    },
    '9300605000048': {
      'name': 'Lay\'s Classic',
      'brand': 'PepsiCo',
      'ingredients': [
        'potatoes',
        'vegetable oil',
        'salt'
      ],
      'allergens': [],
      'image': 'https://example.com/lays-classic.jpg',
      'crossContamination': ['milk', 'wheat', 'nuts'],
      'processingFacility': 'Facility processes: milk, wheat, nuts'
    },
    '9300605000049': {
      'name': 'Oreo Original',
      'brand': 'Mondelez',
      'ingredients': [
        'wheat flour',
        'sugar',
        'vegetable oil',
        'cocoa',
        'salt',
        'raising agents',
        'flavours'
      ],
      'allergens': ['wheat'],
      'image': 'https://example.com/oreo.jpg',
      'crossContamination': ['milk', 'nuts', 'soy'],
      'processingFacility': 'Facility processes: wheat, milk, nuts, soy'
    },
    '9300605000050': {
      'name': 'Coca-Cola Classic',
      'brand': 'Coca-Cola',
      'ingredients': [
        'carbonated water',
        'sugar',
        'caramel',
        'phosphoric acid',
        'natural flavours',
        'caffeine'
      ],
      'allergens': [],
      'image': 'https://example.com/coca-cola.jpg',
      'crossContamination': [],
      'processingFacility': 'Dedicated beverage facility'
    }
  };

  // Enhanced allergen synonyms and variations with comprehensive international support
  static final Map<String, List<String>> _allergenSynonyms = {
    'peanuts': ['peanut', 'peanuts', 'arachis hypogaea', 'groundnut', 'ground nuts', 'monkey nuts', 'peanut oil', 'peanut flour', 'peanut protein', 'cacahuète', 'cacahuètes', 'arachide', 'arachides'],
    'tree nuts': ['tree nuts', 'tree nut', 'nuts', 'nut', 'almond', 'almonds', 'walnut', 'walnuts', 'cashew', 'cashews', 'pecan', 'pecans', 'pistachio', 'pistachios', 'hazelnut', 'hazelnuts', 'macadamia', 'macadamias', 'brazil nut', 'brazil nuts', 'pine nut', 'pine nuts', 'chestnut', 'chestnuts', 'almond oil', 'walnut oil', 'cashew oil', 'macadamia oil', 'amande', 'amandes', 'noix', 'noisette', 'noisettes', 'noix de cajou', 'noix de pécan', 'pistache', 'pistaches'],
    'almond': ['almond', 'almonds', 'almond oil', 'almond flour', 'almond meal', 'almond protein', 'amande', 'amandes'],
    'cashew': ['cashew', 'cashews', 'cashew oil', 'cashew butter', 'noix de cajou'],
    'hazelnut': ['hazelnut', 'hazelnuts', 'hazelnut oil', 'hazelnut flour', 'noisette', 'noisettes'],
    'pecan': ['pecan', 'pecans', 'pecan oil', 'noix de pécan'],
    'walnut': ['walnut', 'walnuts', 'walnut oil', 'walnut flour'],
    'chestnut': ['chestnut', 'chestnuts', 'chestnut flour'],
    'milk': ['milk', 'dairy', 'cream', 'butter', 'cheese', 'yogurt', 'yoghurt', 'whey', 'casein', 'lactose', 'milk powder', 'milk protein', 'skim milk', 'full cream milk', 'whole milk', 'low fat milk', 'milk solids', 'milk fat', 'milk sugar', 'lactose', 'lactoglobulin', 'lactalbumin', 'cheese powder', 'dairy powder', 'cream powder', 'butter powder', 'lait', 'crème', 'beurre', 'fromage', 'yaourt', 'lactosérum', 'caséine', 'lactose', 'poudre de lait', 'protéine de lait', 'solides de lait'],
    'eggs': ['egg', 'eggs', 'egg white', 'egg yolk', 'albumin', 'ovalbumin', 'lysozyme', 'vitellin', 'livetin', 'apovitellenin', 'phosvitin', 'egg powder', 'dried egg', 'egg protein', 'egg solids', 'œuf', 'œufs', 'blanc d\'œuf', 'jaune d\'œuf', 'albumine', 'ovalbumine'],
    'soy': ['soy', 'soya', 'soybean', 'soybeans', 'soy lecithin', 'soy protein', 'tofu', 'miso', 'tempeh', 'edamame', 'soy flour', 'soy oil', 'soy sauce', 'soy milk', 'soy isolate', 'soy concentrate', 'lécithine de soja', 'soja', 'lécithine', 'soja', 'soybean', 'haricot de soja', 'haricots de soja', 'sauce soja'],
    'wheat': ['wheat', 'wheat flour', 'wheat protein', 'gluten', 'bread', 'pasta', 'cereal', 'durum wheat', 'spelt', 'kamut', 'wheat starch', 'wheat bran', 'wheat germ', 'wheat gluten', 'vital wheat gluten', 'wheat protein isolate', 'farine de blé', 'farine blé', 'blé', 'farine', 'blé dur', 'épeautre', 'amidon de blé', 'son de blé', 'germe de blé', 'gluten de blé'],
    'fish': ['fish', 'salmon', 'tuna', 'cod', 'haddock', 'anchovy', 'anchovies', 'bass', 'flounder', 'mackerel', 'sardines', 'fish oil', 'fish sauce', 'fish protein', 'fish gelatin', 'fish collagen', 'poisson', 'saumon', 'thon', 'morue', 'anchois', 'bar', 'flétan', 'maquereau', 'sardines', 'huile de poisson', 'sauce de poisson'],
    'shellfish': ['shrimp', 'prawn', 'crab', 'lobster', 'oyster', 'clam', 'mussel', 'scallop', 'crayfish', 'yabby', 'marron', 'moreton bay bug', 'shrimp paste', 'prawn paste', 'crab meat', 'lobster meat', 'crevette', 'crevettes', 'crabe', 'homard', 'huître', 'huîtres', 'palourde', 'moule', 'moules', 'coquille saint-jacques', 'écrevisse'],
    'sesame': ['sesame', 'sesame seed', 'sesame seeds', 'tahini', 'sesame oil', 'benne', 'gingelly', 'sesame flour', 'sesame protein', 'sésame', 'graine de sésame', 'graines de sésame', 'huile de sésame'],
    'sulfites': ['sulfite', 'sulfites', 'sulphite', 'sulphites', 'sulfur dioxide', 'sulphur dioxide', 'sodium metabisulphite', 'potassium metabisulphite', 'sodium sulfite', 'potassium sulfite', 'sulfite', 'sulfites', 'dioxyde de soufre', 'métabisulfite de sodium', 'métabisulfite de potassium'],
    'mustard': ['mustard', 'mustard seed', 'mustard powder', 'mustard oil', 'mustard flour', 'mustard protein', 'moutarde', 'graine de moutarde', 'poudre de moutarde', 'huile de moutarde'],
    'celery': ['celery', 'celery seed', 'celery salt', 'celery root', 'celeriac', 'celery powder', 'céleri', 'graine de céleri', 'sel de céleri', 'céleri-rave'],
    'lupin': ['lupin', 'lupine', 'lupini', 'lupin flour', 'lupin bean', 'lupin protein', 'lupin', 'lupine', 'farine de lupin', 'haricot de lupin'],
    'molluscs': ['mollusc', 'molluscs', 'snail', 'snails', 'abalone', 'whelk', 'periwinkle', 'pipi', 'cockle', 'mussel', 'oyster', 'clam', 'scallop', 'mollusque', 'mollusques', 'escargot', 'escargots', 'ormeau', 'buccin', 'bigorneau', 'coque', 'moule', 'huître', 'palourde'],
    // Additional grains
    'corn': ['corn', 'maize', 'corn flour', 'corn starch', 'corn syrup', 'corn oil', 'corn meal', 'corn grits', 'corn protein', 'maïs', 'farine de maïs', 'amidon de maïs', 'sirop de maïs', 'huile de maïs'],
    'rice': ['rice', 'rice flour', 'rice starch', 'rice syrup', 'rice protein', 'brown rice', 'white rice', 'wild rice', 'rice bran', 'rice germ', 'riz', 'farine de riz', 'amidon de riz', 'sirop de riz'],
    'oats': ['oats', 'oat flour', 'oat bran', 'oat protein', 'rolled oats', 'steel cut oats', 'oatmeal', 'avoine', 'farine d\'avoine', 'son d\'avoine'],
    'barley': ['barley', 'barley flour', 'barley malt', 'barley protein', 'pearl barley', 'barley starch', 'orge', 'farine d\'orge', 'malt d\'orge'],
    'rye': ['rye', 'rye flour', 'rye bread', 'rye protein', 'seigle', 'farine de seigle', 'pain de seigle'],
    'quinoa': ['quinoa', 'quinoa flour', 'quinoa protein', 'quinoa seeds', 'quinoa flakes'],
    'buckwheat': ['buckwheat', 'buckwheat flour', 'buckwheat groats', 'buckwheat protein', 'sarrasin', 'farine de sarrasin'],
    // Additional nuts
    'coconut': ['coconut', 'coconut oil', 'coconut flour', 'coconut milk', 'coconut cream', 'coconut protein', 'coconut sugar', 'coconut water', 'noix de coco', 'huile de noix de coco', 'farine de noix de coco', 'lait de noix de coco'],
    'brazil nut': ['brazil nut', 'brazil nuts', 'brazil nut oil', 'brazil nut flour', 'noix du brésil', 'noix du brésil', 'huile de noix du brésil'],
    'pistachio': ['pistachio', 'pistachios', 'pistachio oil', 'pistachio flour', 'pistachio protein', 'pistache', 'pistaches', 'huile de pistache'],
    'macadamia': ['macadamia', 'macadamias', 'macadamia nut', 'macadamia nuts', 'macadamia oil', 'macadamia flour', 'macadamia protein', 'noix de macadamia', 'huile de macadamia'],
    'pine nut': ['pine nut', 'pine nuts', 'pignoli', 'pignolia', 'pine kernel', 'pine kernels', 'pignon', 'pignons'],
    // Fruits and vegetables
    'kiwi': ['kiwi', 'kiwi fruit', 'kiwifruit', 'kiwi protein', 'kiwi extract'],
    'banana': ['banana', 'bananas', 'banana flour', 'banana protein', 'banana extract', 'banane', 'bananes'],
    'tomato': ['tomato', 'tomatoes', 'tomato paste', 'tomato sauce', 'tomato powder', 'tomato protein', 'tomate', 'tomates'],
    'strawberry': ['strawberry', 'strawberries', 'strawberry extract', 'strawberry protein', 'fraise', 'fraises'],
  };

  // Cross-contamination risk levels
  static final Map<String, String> _crossContaminationRisk = {
    'high': 'High risk of cross-contamination',
    'medium': 'Medium risk of cross-contamination',
    'low': 'Low risk of cross-contamination',
    'none': 'No known cross-contamination risk'
  };

  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    await initialize();

    for (final candidate in BarcodeUtils.lookupCandidates(barcode)) {
      final product = _productDatabase[candidate];
      if (product != null) return product;
    }

    return null;
  }

  /// Word-boundary match so "nuts" does not hit "peanuts" and "tree nut" hits
  /// both "tree nut" and the pack phrasing "tree nuts".
  static bool textContainsAllergenTerm(String text, String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(
      '\\b${RegExp.escape(trimmed)}\\b',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static const List<String> _individualTreeNutKeys = [
    'almond',
    'cashew',
    'hazelnut',
    'pecan',
    'walnut',
    'brazil nut',
    'pistachio',
    'macadamia',
    'pine nut',
    'chestnut',
  ];

  /// Pack-level "tree nuts" / "nuts" / en:nuts traces — not a specific nut.
  static const List<String> _genericTreeNutWarningTerms = [
    'tree nuts',
    'tree nut',
    'nuts',
    'nut',
    'en:nuts',
  ];

  static bool _isIndividualTreeNutAllergy(String allergyName) {
    final lower = allergyName.toLowerCase().trim();
    if (lower == 'tree nuts' || lower == 'tree nut') return false;
    if (_genericTreeNutWarningTerms.contains(lower)) return false;
    if (_individualTreeNutKeys.contains(lower)) return true;
    for (final key in _individualTreeNutKeys) {
      if (_allergenSynonyms[key]?.contains(lower) == true) return true;
    }
    return _allergenSynonyms['tree nuts']!.contains(lower);
  }

  /// Synonyms used to match a saved user allergy against ingredients / traces.
  ///
  /// "Tree Nuts" matches any tree nut. An individual nut matches only that nut,
  /// plus generic pack traces ("tree nuts", "nuts", en:nuts).
  /// When Tree Nuts is saved with a child subset, the parent matches generic
  /// traces only; selected children match their own ingredients.
  static List<String> _synonymsForUserAllergy(
    String allergyName, {
    bool treeNutsGenericOnly = false,
  }) {
    final lower = allergyName.toLowerCase().trim();
    if (lower.isEmpty) return const [];

    if (lower == 'tree nuts' || lower == 'tree nut') {
      if (treeNutsGenericOnly) {
        return List<String>.from(_genericTreeNutWarningTerms);
      }
      return List<String>.from(_allergenSynonyms['tree nuts']!);
    }

    if (_allergenSynonyms.containsKey(lower)) {
      return List<String>.from(_allergenSynonyms[lower]!);
    }

    for (final entry in _allergenSynonyms.entries) {
      if (entry.key == 'tree nuts') continue;
      if (entry.value.contains(lower)) {
        return List<String>.from(entry.value);
      }
    }

    if (_allergenSynonyms['tree nuts']!.contains(lower) &&
        !_genericTreeNutWarningTerms.contains(lower)) {
      return [lower];
    }

    return [lower];
  }

  static List<String> _warningSynonymsForUserAllergy(
    String allergyName, {
    bool treeNutsGenericOnly = false,
    bool skipExtraGenericTreeNutTerms = false,
  }) {
    final synonyms = _synonymsForUserAllergy(
      allergyName,
      treeNutsGenericOnly: treeNutsGenericOnly,
    );
    if (skipExtraGenericTreeNutTerms) {
      return synonyms;
    }
    return _withGenericTreeNutTermsIfNeeded(allergyName, synonyms);
  }

  static List<String> _withGenericTreeNutTermsIfNeeded(
    String keyOrName,
    List<String> synonyms,
  ) {
    final result = List<String>.from(synonyms);
    if (_isIndividualTreeNutAllergy(keyOrName)) {
      for (final term in _genericTreeNutWarningTerms) {
        if (!result.contains(term)) result.add(term);
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> analyzeAllergens(
    List<String> ingredients,
    List<Map<String, dynamic>> userAllergies,
  ) {
    List<Map<String, dynamic>> detectedAllergens = [];
    
    // Convert ingredients to lowercase for matching
    List<String> lowerIngredients = ingredients.map((e) => e.toLowerCase()).toList();
    
    // Also create a combined string for complex ingredient lists
    String combinedIngredients = lowerIngredients.join(' ');
    
    if (kDebugMode) {
      print('ProductDatabaseService: Analyzing allergens');
      print('ProductDatabaseService: Ingredients: $ingredients');
      print('ProductDatabaseService: Lower ingredients: $lowerIngredients');
      print('ProductDatabaseService: Combined ingredients: $combinedIngredients');
      print('ProductDatabaseService: User allergies: ${userAllergies.length}');
      for (var allergy in userAllergies) {
        print('ProductDatabaseService: User allergy - ${allergy['name']} (${allergy['severity']})');
      }
    }
    
    // Parse ingredients to separate actual ingredients from warnings
    Map<String, dynamic> parsedIngredients = parseIngredientsWithWarnings(ingredients);
    List<String> actualIngredients = parsedIngredients['actualIngredients'];
    List<String> crossContaminationWarnings = parsedIngredients['crossContaminationWarnings'];
    List<String> processingFacilityWarnings = parsedIngredients['processingFacilityWarnings'];
    
    if (kDebugMode) {
      print('ProductDatabaseService: Actual ingredients: $actualIngredients');
      print('ProductDatabaseService: Cross-contamination warnings: $crossContaminationWarnings');
      print('ProductDatabaseService: Processing facility warnings: $processingFacilityWarnings');
    }
    
    final allergyNames = userAllergies
        .map((allergy) => allergy['name']?.toString() ?? '')
        .toList();
    final treeNutsSubset = TreeNutsGrouping.isSubset(allergyNames);
    final hasTreeNutsParent = TreeNutsGrouping.hasParent(allergyNames);

    for (Map<String, dynamic> allergy in userAllergies) {
      String allergyName = allergy['name'].toString().toLowerCase();
      
      if (kDebugMode) {
        print('ProductDatabaseService: Checking allergy: $allergyName');
      }
      
      // Check if this allergy is in the allergen synonyms
      bool found = false;
      String matchedIngredient = '';
      String allergenCategory = '';
      String detectionMethod = '';
      bool isCrossContamination = false;

      final treeNutsGenericOnly =
          treeNutsSubset && TreeNutsGrouping.isParentName(allergyName);
      final skipExtraGenericTreeNutTerms = hasTreeNutsParent &&
          _isIndividualTreeNutAllergy(allergyName);
      final synonyms = _synonymsForUserAllergy(
        allergyName,
        treeNutsGenericOnly: treeNutsGenericOnly,
      );
      final warningSynonyms = _warningSynonymsForUserAllergy(
        allergyName,
        treeNutsGenericOnly: treeNutsGenericOnly,
        skipExtraGenericTreeNutTerms: skipExtraGenericTreeNutTerms,
      );
      if (synonyms.isNotEmpty) {
        if (kDebugMode) {
          print('ProductDatabaseService: Found allergy "$allergyName" synonyms: $synonyms');
        }
        allergenCategory = (allergyName == 'tree nuts' || allergyName == 'tree nut')
            ? 'tree nuts'
            : allergyName;

        for (String synonym in warningSynonyms) {
          for (String warning in crossContaminationWarnings) {
            if (textContainsAllergenTerm(warning, synonym)) {
              if (kDebugMode) {
                print('ProductDatabaseService: CROSS-CONTAMINATION MATCH FOUND! Synonym "$synonym" found in warning "$warning"');
              }
              found = true;
              matchedIngredient = warning;
              detectionMethod = 'Cross-contamination warning';
              isCrossContamination = true;
              break;
            }
          }
          if (found) break;
        }

        if (!found) {
          for (String synonym in synonyms) {
            if (kDebugMode) {
              print('ProductDatabaseService: Checking synonym "$synonym" in actual ingredients');
            }
            for (String ingredient in actualIngredients) {
              if (textContainsAllergenTerm(ingredient, synonym)) {
                if (kDebugMode) {
                  print('ProductDatabaseService: ACTUAL INGREDIENT MATCH FOUND! Synonym "$synonym" found in ingredient "$ingredient"');
                }
                found = true;
                matchedIngredient = ingredient;
                detectionMethod = 'Actual ingredient match';
                isCrossContamination = false;
                break;
              }
            }
            if (found) break;
          }

          if (!found) {
            String combinedActual = actualIngredients.join(' ').toLowerCase();
            for (String synonym in synonyms) {
              if (textContainsAllergenTerm(combinedActual, synonym)) {
                if (kDebugMode) {
                  print('ProductDatabaseService: COMBINED INGREDIENT MATCH FOUND! Synonym "$synonym" found in combined ingredients');
                }
                found = true;
                matchedIngredient = 'Found in ingredient list';
                detectionMethod = 'Combined ingredient match';
                isCrossContamination = false;
                break;
              }
            }
          }
        }
      }
      
             // Also check direct ingredient match (prioritize cross-contamination)
       if (!found) {
         // Check cross-contamination warnings for direct match first
         for (String warning in crossContaminationWarnings) {
           if (textContainsAllergenTerm(warning, allergyName)) {
             if (kDebugMode) {
               print('ProductDatabaseService: DIRECT CROSS-CONTAMINATION MATCH FOUND! Allergy "$allergyName" found in warning "$warning"');
             }
             found = true;
             matchedIngredient = warning;
             allergenCategory = allergyName;
             detectionMethod = 'Direct cross-contamination warning';
             isCrossContamination = true;
             break;
           }
         }
         
         // If not found in cross-contamination, check actual ingredients
         if (!found) {
           for (String ingredient in actualIngredients) {
             if (textContainsAllergenTerm(ingredient, allergyName)) {
               if (kDebugMode) {
                 print('ProductDatabaseService: DIRECT ACTUAL INGREDIENT MATCH FOUND! Allergy "$allergyName" found in ingredient "$ingredient"');
               }
               found = true;
               matchedIngredient = ingredient;
               allergenCategory = allergyName;
               detectionMethod = 'Direct actual ingredient match';
               isCrossContamination = false;
               break;
             }
           }
         }
       }
      
      if (found) {
        if (kDebugMode) {
          print('ProductDatabaseService: FOUND ALLERGEN - ${allergy['name']} in ingredient: $matchedIngredient (Method: $detectionMethod, Cross-contamination: $isCrossContamination)');
        }
        detectedAllergens.add({
          'name': allergy['name'],
          'severity': allergy['severity'],
          'category': allergy['category'],
          'matchedIngredient': matchedIngredient,
          'allergenCategory': allergenCategory,
          'notes': allergy['notes'],
          'detectionMethod': detectionMethod,
          'isCrossContamination': isCrossContamination,
          'confidence': isCrossContamination ? 0.7 : 1.0, // Lower confidence for cross-contamination
        });
      } else {
        if (kDebugMode) {
          print('ProductDatabaseService: NO MATCH found for allergy: ${allergy['name']}');
        }
      }
    }
    
    return detectedAllergens;
  }

  /// Parse ingredients to separate actual ingredients from warnings
  static Map<String, dynamic> parseIngredientsWithWarnings(List<String> ingredients) {
    List<String> actualIngredients = [];
    List<String> crossContaminationWarnings = [];
    List<String> processingFacilityWarnings = [];
    
    // Common cross-contamination phrases
    List<String> crossContaminationPhrases = [
      'may contain',
      'may contain traces',
      'may contain traces of',
      'may contain small amounts',
      'may contain minute amounts',
      'may contain trace amounts',
      'may contain small traces',
      'allergen information',
      'allergen advice',
      'allergen warning',
      'contains traces',
      'contains small amounts',
      'may be present',
      'may be present in small amounts',
      'produced in a facility',
      'manufactured in a facility',
      'packaged in a facility',
      'processed in a facility',
      'made in a facility',
      'handled in a facility',
    ];
    
    // Common processing facility phrases
    List<String> processingFacilityPhrases = [
      'processed in a facility',
      'manufactured in a facility',
      'packaged in a facility',
      'produced in a facility',
      'made in a facility',
      'handled in a facility',
      'facility processes',
      'facility that processes',
      'facility that manufactures',
      'facility that packages',
    ];
    
    if (kDebugMode) {
      print('ProductDatabaseService: parseIngredientsWithWarnings - Input ingredients: $ingredients');
    }
    
    for (String ingredient in ingredients) {
      String lowerIngredient = ingredient.toLowerCase();
      bool isWarning = false;
      
      if (kDebugMode) {
        print('ProductDatabaseService: Processing ingredient: "$ingredient"');
      }
      
      // Check for cross-contamination warnings
      for (String phrase in crossContaminationPhrases) {
        if (lowerIngredient.contains(phrase)) {
          if (kDebugMode) {
            print('ProductDatabaseService: Found cross-contamination phrase "$phrase" in ingredient "$ingredient"');
          }
          crossContaminationWarnings.add(ingredient);
          isWarning = true;
          break;
        }
      }
      
      // Check for processing facility warnings
      if (!isWarning) {
        for (String phrase in processingFacilityPhrases) {
          if (lowerIngredient.contains(phrase)) {
            if (kDebugMode) {
              print('ProductDatabaseService: Found processing facility phrase "$phrase" in ingredient "$ingredient"');
            }
            processingFacilityWarnings.add(ingredient);
            isWarning = true;
            break;
          }
        }
      }
      
      // If not a warning, it's an actual ingredient
      if (!isWarning) {
        if (kDebugMode) {
          print('ProductDatabaseService: Adding as actual ingredient: "$ingredient"');
        }
        actualIngredients.add(ingredient);
      }
    }
    
    if (kDebugMode) {
      print('ProductDatabaseService: parseIngredientsWithWarnings - Results:');
      print('  Actual ingredients: $actualIngredients');
      print('  Cross-contamination warnings: $crossContaminationWarnings');
      print('  Processing facility warnings: $processingFacilityWarnings');
    }
    
    return {
      'actualIngredients': actualIngredients,
      'crossContaminationWarnings': crossContaminationWarnings,
      'processingFacilityWarnings': processingFacilityWarnings,
    };
  }

  /// Extract individual items listed in "may contain" sections of ingredient text.
  static List<String> extractMayContainListing(List<String> ingredients) {
    if (ingredients.isEmpty) return [];

    final items = <String>[];
    final seen = <String>{};

    void addFromListing(String listing) {
      var cleaned = listing.trim();
      if (cleaned.isEmpty) return;

      cleaned = cleaned
          .replaceAll(
            RegExp(r'^(may contain( traces( of)?)?|contains traces( of)?|may be present)[:\s]*', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'\.$'), '')
          .trim();

      if (cleaned.isEmpty) return;

      for (final part in cleaned.split(RegExp(r',|\band\b', caseSensitive: false))) {
        final item = part.trim();
        if (item.length > 1 && seen.add(item.toLowerCase())) {
          items.add(_formatMayContainItem(item));
        }
      }
    }

    final combined = ingredients.join(' ');
    final mayContainPattern = RegExp(
      r'may contain(?: traces(?: of)?)?[:\s]+([^\.]+)',
      caseSensitive: false,
    );
    for (final match in mayContainPattern.allMatches(combined)) {
      addFromListing(match.group(1) ?? '');
    }

    // "Egg, peanuts, sesame, and other tree nuts may be present"
    final mayBePresentIndex = combined.toLowerCase().indexOf('may be present');
    if (mayBePresentIndex > 0) {
      var listing = combined.substring(0, mayBePresentIndex).trim();
      final lastPeriod = listing.lastIndexOf('.');
      if (lastPeriod >= 0) {
        listing = listing.substring(lastPeriod + 1).trim();
      }
      addFromListing(listing);
    }

    // "May contain traces of Peanut, Egg, Sesame and tree Nut"
    final tracesOfPattern = RegExp(
      r'(?:may contain )?traces of[:\s]+([^\.]+)',
      caseSensitive: false,
    );
    for (final match in tracesOfPattern.allMatches(combined)) {
      addFromListing(match.group(1) ?? '');
    }

    final parsed = parseIngredientsWithWarnings(ingredients);
    for (final warning in parsed['crossContaminationWarnings'] as List<String>) {
      addFromListing(warning);
    }

    return items;
  }

  /// Collect may-contain items from ingredient text and product metadata.
  static List<String> collectMayContainItems({
    required List<String> ingredients,
    Map<String, dynamic>? product,
  }) {
    final seen = <String>{};
    final items = <String>[];

    void addItem(String value) {
      final trimmed = HtmlTextUtils.strip(value);
      if (trimmed.length <= 1) return;
      if (seen.add(trimmed.toLowerCase())) {
        items.add(_formatMayContainItem(trimmed));
      }
    }

    for (final item in extractMayContainListing(ingredients)) {
      addItem(item);
    }

    if (product == null) return items;

    _addTraceTagItems(product['traces_tags'], addItem);
    for (final trace in (product['traces']?.toString() ?? '').split(',')) {
      addItem(trace.replaceAll('_', ' '));
    }

    for (final item in product['mayContainItems'] as List<dynamic>? ?? []) {
      addItem(item.toString());
    }

    for (final entry in product['crossContamination'] as List<dynamic>? ?? []) {
      final text = entry.toString().trim();
      if (text.isEmpty) continue;
      if (text.toLowerCase().contains('may contain')) {
        for (final item in extractMayContainListing([text])) {
          addItem(item);
        }
      } else {
        addItem(text);
      }
    }

    for (final warning in product['crossContaminationWarnings'] as List<dynamic>? ?? []) {
      if (warning is Map<String, dynamic>) {
        final allergen = warning['allergen']?.toString();
        if (allergen != null && allergen.isNotEmpty && allergen.toLowerCase() != 'unknown') {
          addItem(allergen);
        }
        final original = warning['originalWarning']?.toString();
        if (original != null && original.isNotEmpty) {
          for (final item in extractMayContainListing([original])) {
            addItem(item);
          }
        }
      } else if (warning is String) {
        for (final item in extractMayContainListing([warning])) {
          addItem(item);
        }
      }
    }

    return items;
  }

  static const Map<String, String> _traceTagNames = {
    'peanuts': 'Peanuts',
    'tree-nuts': 'Tree Nuts',
    'nuts': 'Tree Nuts',
    'milk': 'Milk',
    'eggs': 'Egg',
    'egg': 'Egg',
    'soybeans': 'Soy',
    'soy': 'Soy',
    'wheat': 'Wheat',
    'gluten': 'Gluten',
    'fish': 'Fish',
    'crustaceans': 'Shellfish',
    'sesame-seeds': 'Sesame',
    'sesame': 'Sesame',
    'sulphur-dioxide-and-sulphites': 'Sulphites',
    'mustard': 'Mustard',
    'celery': 'Celery',
    'lupin': 'Lupin',
    'molluscs': 'Molluscs',
  };

  static void _addTraceTagItems(dynamic tags, void Function(String) addItem) {
    if (tags is! List) return;
    for (final tag in tags) {
      final raw = tag.toString().replaceFirst(RegExp(r'^en:'), '').toLowerCase();
      addItem(_traceTagNames[raw] ?? raw.replaceAll('-', ' '));
    }
  }

  static const Map<String, String> _mayContainCanonicalNames = {
    'nuts': 'Tree Nuts',
    'nut': 'Tree Nuts',
    'tree nut': 'Tree Nuts',
    'tree nuts': 'Tree Nuts',
    'tree-nuts': 'Tree Nuts',
    'en:nuts': 'Tree Nuts',
  };

  static String _formatMayContainItem(String item) {
    final collapsed = item
        .split(' ')
        .where((word) => word.isNotEmpty)
        .join(' ');
    final canonical = _mayContainCanonicalNames[collapsed.toLowerCase()];
    if (canonical != null) return canonical;
    return collapsed
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static Map<String, dynamic> getScanResult(
    String barcode,
    List<Map<String, dynamic>> userAllergies,
  ) {
    final product = _productDatabase[barcode];
    
    if (product == null) {
      return {
        'success': false,
        'message': 'Product not found in database',
        'barcode': barcode,
      };
    }
    
    final detectedAllergens = analyzeAllergens(
      List<String>.from(product['ingredients']),
      userAllergies,
    );
    
    // Enhanced result with cross-contamination and processing facility info
    return {
      'success': true,
      'product': product,
      'detectedAllergens': detectedAllergens,
      'barcode': barcode,
      'scanDate': DateTime.now().toIso8601String(),
      'isSafe': detectedAllergens.isEmpty,
      'crossContamination': product['crossContamination'] ?? [],
      'processingFacility': product['processingFacility'] ?? 'No processing facility information available',
      'allergenAnalysis': {
        'totalIngredients': product['ingredients'].length,
        'analyzedIngredients': product['ingredients'].length,
        'detectionMethod': 'Comprehensive allergen database matching',
        'lastUpdated': DateTime.now().toIso8601String(),
      }
    };
  }

  // Method to add a new product to the database (for testing)
  static bool _initialized = false;

  /// Merge curated manual databases into the local fallback catalog.
  ///
  /// Curated entries always win on barcode collisions so synthetic
  /// `9300605000xxx` placeholders cannot shadow pack-accurate data.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    for (final entry in OpenFoodFactsService.manualProductDatabase.entries) {
      _productDatabase[entry.key] = Map<String, dynamic>.from(entry.value);
    }

    // Overlay pack-accurate curated data onto older synthetic SKUs so the
    // bundled catalog matches the real Australian barcodes above.
    const syntheticToReal = <String, String>{
      '9300605000005': '9300605126527', // Milo
      '9300605000007': '9310060011030', // Uncle Tobys oats
      '9300605000008': '9310015241888', // Smith's original
      '9300605000009': '9310015240614', // Red Rock Deli
      '9300605000010': '9310988009638', // Kettle sea salt
      '9300605000012': '9310072026404', // Jatz
      '9300605000014': '9310072023496', // Iced VoVo
      '9300605000017': '9310072029559', // Tiny Teddy
      '9300605000023': '9310053105357', // Mainland Extra Tasty
      '9300605000024': '9311493003388', // Bundaberg Ginger Beer
      '9300605000025': '9310179006668', // Golden Circle pineapple
      '9300605000030': '9310012021049', // MasterFoods tomato sauce
      '9300605000031': '9310055102699', // Kellogg's Corn Flakes
      '9300605000034': '9310015248788', // Twisties Cheese
      '9300605000039': '9350177000275', // Sirena tuna
      '9300605000040': '9310174157488', // McCain SuperFries
      '9300605000006': '9310055106789', // Nutri-Grain
      '9300605000015': '9310072001005', // Monte Carlo
      '9300605000016': '9310072001777', // Scotch Finger
      '9300605000018': '9310072001579', // Choc Ripple
      '9300605000019': '9310072002095', // Kingston
      '9300605000026': '9300605099531', // Allen's Snakes Alive
      '9300605000027': '9300605124028', // Allen's Big Red Frogs
      '9300605000028': '9300605012554', // Allen's Minties
      '9300605000032': '9310055105867', // Rice Bubbles
      '9300605000033': '9310055105898', // Special K
      '9300605000035': '9310015248771', // Twisties Chicken
      '9300605000038': '9300462137575', // John West tuna
      '9300605000041': '9300605140172', // KitKat Chunky Aero Mint
      '9300605000046': '9310015241918', // Doritos Nacho Cheese
    };
    for (final mapping in syntheticToReal.entries) {
      final real = OpenFoodFactsService.manualProductDatabase[mapping.value];
      if (real == null) continue;
      _productDatabase[mapping.key] = {
        ...Map<String, dynamic>.from(real),
        'demoAliasFor': mapping.value,
      };
    }

    if (kDebugMode) {
      print('ProductDatabaseService: initialized with ${_productDatabase.length} products');
    }
  }

  /// True for bundled fake SKUs in the Nestlé-prefix `93006050000xx` range
  /// that are not curated demo aliases. Those must not block live lookup.
  static bool isUnverifiedSyntheticBarcode(String barcode) {
    if (!barcode.startsWith('93006050000')) return false;
    return !OpenFoodFactsService.manualProductDatabase.containsKey(barcode);
  }

  static void addProduct(String barcode, Map<String, dynamic> product) {
    final existing = _productDatabase[barcode];
    if (existing != null) {
      _productDatabase[barcode] = {
        ...Map<String, dynamic>.from(existing),
        ...product,
      };
    } else {
      _productDatabase[barcode] = Map<String, dynamic>.from(product);
    }
  }

  /// Replace a runtime entry entirely (used to restore curated data).
  static void replaceProduct(String barcode, Map<String, dynamic> product) {
    _productDatabase[barcode] = Map<String, dynamic>.from(product);
  }

  /// True when an ingredient row is a may-contain / traces statement, not a recipe item.
  static bool isMayContainStatement(String item) {
    final text = item.toLowerCase().trim();
    return text.contains('may contain') ||
        text.contains('may be present') ||
        text.contains('contains traces') ||
        text.startsWith('traces of');
  }

  /// Ingredient chips should not also list the may-contain sentence.
  static List<String> ingredientsExcludingMayContain(List<String> ingredients) {
    return ingredients
        .map(HtmlTextUtils.strip)
        .where((item) => item.isNotEmpty && !isMayContainStatement(item))
        .toList();
  }

  // Method to get all products (for testing)
  static Map<String, Map<String, dynamic>> getAllProducts() {
    return Map.from(_productDatabase);
  }

  // Method to get cross-contamination risk assessment
  static Map<String, dynamic> getCrossContaminationRisk(String barcode) {
    final product = _productDatabase[barcode];
    if (product == null) {
      return {
        'risk': 'unknown',
        'message': 'Product not found',
        'crossContamination': [],
        'processingFacility': 'Unknown'
      };
    }

    final crossContamination = product['crossContamination'] ?? [];
    String riskLevel = 'none';
    
    if (crossContamination.length > 3) {
      riskLevel = 'high';
    } else if (crossContamination.length > 1) {
      riskLevel = 'medium';
    } else if (crossContamination.length == 1) {
      riskLevel = 'low';
    }

    return {
      'risk': riskLevel,
      'message': _crossContaminationRisk[riskLevel] ?? 'Unknown risk level',
      'crossContamination': crossContamination,
      'processingFacility': product['processingFacility'] ?? 'No information available'
    };
  }

  // Method to search products by name or brand
  static List<Map<String, dynamic>> searchProducts(String query) {
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();
    
    for (String barcode in _productDatabase.keys) {
      final product = _productDatabase[barcode]!;
      final name = product['name'].toString().toLowerCase();
      final brand = product['brand'].toString().toLowerCase();
      
      if (name.contains(lowerQuery) || brand.contains(lowerQuery)) {
        results.add({
          'barcode': barcode,
          ...product,
        });
      }
    }
    
    return results;
  }

  // Method to get allergen statistics
  static Map<String, dynamic> getAllergenStatistics() {
    final stats = <String, int>{};
    final totalProducts = _productDatabase.length;
    
    for (String barcode in _productDatabase.keys) {
      final product = _productDatabase[barcode]!;
      final allergens = product['allergens'] as List<dynamic>? ?? [];
      
      for (String allergen in allergens) {
        stats[allergen] = (stats[allergen] ?? 0) + 1;
      }
    }
    
    return {
      'totalProducts': totalProducts,
      'allergenCounts': stats,
      'mostCommonAllergens': (() {
        final sortedEntries = stats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return sortedEntries
          .take(5)
          .map((e) => {'allergen': e.key, 'count': e.value})
          .toList();
      })(),
    };
  }
} 