import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProGlassesQuestionnaireScreen extends StatefulWidget {
  @override
  _ProGlassesQuestionnaireScreenState createState() =>
      _ProGlassesQuestionnaireScreenState();
}

class _ProGlassesQuestionnaireScreenState
    extends State<ProGlassesQuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;

  // Store detailed answers (each answer is a Map with 'label' and 'image')
  Map<int, dynamic> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'question': "Quel type de lunettes souhaitez-vous ?",
      'type': 'single',
      'options': [
        {
          'label': 'Lunettes de Soleil',
          'image': 'assets/images/sun.jpeg',
        },
        {
          'label': 'Lunettes de Vue',
          'image': 'assets/images/vu.jpeg',
        }
      ],
      'icon': Icons.wb_sunny,
    },
    {
      'question': "Quel style vous correspond le mieux ?",
      'type': 'single',
      'options': [
        {'label': 'Féminin', 'image': 'assets/images/femme.avif'},
        {'label': 'Masculin', 'image': 'assets/images/homme.avif'}
      ],
      'icon': Icons.female,
    },
    {
      'question': "Quelle forme de monture vous convient ?",
      'type': 'single',
      'options': [
        {
          'label': 'Cat Eye',
          'image': 'assets/cat_eye.png',
        },
        {
          'label': 'Aviateur',
          'image': 'assets/aviator.png',
        },
        {
          'label': 'Rond',
          'image': 'assets/round.png',
        },
        {
          'label': 'Carré',
          'image': 'assets/square.png',
        }
      ],
      'icon': Icons.style,
    },
    {
      'question': "Quelles couleurs aimez-vous ?",
      'type': 'single',
      'options': [
        {
          'label': 'Neutres',
          'image': 'assets/neutral_colors.png',
        },
        {
          'label': 'Noir',
          'image': 'assets/black.png',
        },
        {
          'label': 'Argent',
          'image': 'assets/silver.png',
        },
        {
          'label': 'Colorées',
          'image': 'assets/colorful.png',
        }
      ],
      'icon': Icons.color_lens,
    },
    {
      'question': "Quel matériau privilégiez-vous ?",
      'type': 'single',
      'options': [
        {
          'label': 'Plastique',
          'image': 'assets/plastic.png',
        },
        {
          'label': 'Métal',
          'image': 'assets/metal.png',
        },
        {
          'label': 'Mixte',
          'image': 'assets/mixed_material.png',
        }
      ],
      'icon': Icons.build,
    },
    {
      'question': "Quel est votre budget ?",
      'type': 'single',
      'options': [
        {
          'label': 'Économique (100-250€)',
          'image': 'assets/budget_low.png',
        },
        {
          'label': 'Moyen (250-500€)',
          'image': 'assets/budget_medium.png',
        },
        {
          'label': 'Premium (500-800€)',
          'image': 'assets/budget_high.png',
        },
        {
          'label': 'Haut de gamme (800€+)',
          'image': 'assets/budget_top.png',
        }
      ],
      'icon': Icons.attach_money,
    },
  ];

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
          duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      _showDetailedSummary();
    }
  }

  void _showDetailedSummary() {
    Get.defaultDialog(
      title: "Questionnaire Summary",
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _answers.entries.map((entry) {
            var question = _questions[entry.key];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black87),
                  children: [
                    TextSpan(
                      text: "${question['question']}: \n",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Extracting the label from the answer map
                    TextSpan(
                      text: "${entry.value['label']}",
                      style: TextStyle(color: Colors.deepPurple),
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
          ),
          onPressed: () {
            // Navigate to recommendations screen and pass answers
            Get.toNamed('/recommendations', arguments: _answers);
          },
          child: Text("Confirm"),
        ),
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: Text("Cancel"),
        )
      ],
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    return Animate(
      effects: [
        FadeEffect(duration: 500.ms),
        SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question['question'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple[800],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: question['options'].length,
              itemBuilder: (context, index) {
                var option = question['options'][index];
                return GestureDetector(
                  onTap: () {
                    _answers[_currentQuestionIndex] = option;
                    _nextQuestion();
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          option['image'],
                          height: 120,
                          width: 120,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 10),
                        Text(
                          option['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Colors.deepPurple[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
              SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionWidget(_questions[index]);
                  },
                ),
              ),
              if (_currentQuestionIndex > 0)
                TextButton(
                  onPressed: () {
                    if (_currentQuestionIndex > 0) {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    "Previous",
                    style: TextStyle(color: Colors.deepPurple, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecommendationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Safely handle null or incorrect argument type
    final Map<int, dynamic> answers =
        Get.arguments is Map ? (Get.arguments as Map).cast<int, dynamic>() : {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Glasses Recommendations'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildRecommendationSection(answers),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(Map<int, dynamic> answers) {
    // Generate recommendations based on the answers
    List<Map<String, String>> recommendations =
        _generateRecommendations(answers);

    if (recommendations.isEmpty) {
      return Center(
        child: Text(
          'No recommendations available.',
          style: TextStyle(fontSize: 18, color: Colors.deepPurple),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Glasses',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        SizedBox(height: 16),
        ...recommendations.map((recommendation) {
          return Card(
            elevation: 4,
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(
                recommendation['name'] ?? 'Glasses Model',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(recommendation['description'] ?? ''),
              trailing: Text(
                recommendation['price'] ?? '',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  List<Map<String, String>> _generateRecommendations(
      Map<int, dynamic> answers) {
    List<Map<String, String>> recommendations = [];

    // Safely check if the first answer exists and is a map
    if (answers[0] != null && answers[0] is Map) {
      final envMap = answers[0] as Map<String, String>;
      String? environment = envMap['label'];

      switch (environment) {
        case 'Office with Screens':
          recommendations.add({
            'name': 'ProScreen Elite',
            'description': 'Glasses with blue light protection for screen work',
            'price': '249€'
          });
          break;
        case 'Outdoor Work':
          recommendations.add({
            'name': 'RoadPro Protect',
            'description': 'Robust glasses with enhanced UV protection',
            'price': '299€'
          });
          break;
        case 'Industrial Setting':
          recommendations.add({
            'name': 'SafeWork Pro',
            'description': 'Safety glasses with side protection',
            'price': '199€'
          });
          break;
        case 'No Preference':
          recommendations.add({
            'name': 'Universal Vision',
            'description':
                'Versatile glasses suitable for multiple environments',
            'price': '279€'
          });
          break;
        default:
          recommendations.add({
            'name': 'Classic Comfort',
            'description': 'Standard glasses for general use',
            'price': '229€'
          });
      }
    }

    return recommendations;
  }
}
