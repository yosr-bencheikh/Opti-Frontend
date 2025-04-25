import 'package:flutter/material.dart';

class BoutiqueFilterWidget extends StatefulWidget {
  final Map<String, String> initialFilters;
  final Function(Map<String, String>) onFilterChanged;
  
  const BoutiqueFilterWidget({
    Key? key, 
    required this.onFilterChanged,
    required this.initialFilters,
  }) : super(key: key);

  @override
  _BoutiqueFilterWidgetState createState() => _BoutiqueFilterWidgetState();
}

class _BoutiqueFilterWidgetState extends State<BoutiqueFilterWidget> {
  late Map<String, String> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters);
  }
  
  

  // Liste des villes
  final List<String> _villes = [
    'Toutes les villes',
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Zaghouan',
    'Bizerte',
    'Béja',
    'Jendouba',
    'Le Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Sfax',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Gabès',
    'Medenine',
    'Tataouine',
    'Gafsa',
    'Tozeur',
    'Kebili',
  ];

  void _updateFilter(String key, String value) {
    setState(() {
      _filters[key] = value;
      widget.onFilterChanged(_filters);
    });
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'nom': '',
        'adresse': '',
        'ville': '',
        'categorie': '',
        'note': '',
      };
      widget.onFilterChanged(_filters);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    final isMediumScreen = MediaQuery.of(context).size.width > 600;

    return Container(
  margin: const EdgeInsets.only(top: 16),
  padding: const EdgeInsets.all(12),
  height: isWideScreen ? 180 : (isMediumScreen ? 240 : 360), // <- ici c'est OK
  decoration: BoxDecoration(
    color: theme.cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
  ),
  child: Column( // <- ici c'est OK
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
          Row(
            children: [
              Icon(Icons.store, color: theme.primaryColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'Filtres Boutique',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Réinitialiser',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: isWideScreen
                  ? _buildWideScreenFilters(theme)
                  : (isMediumScreen
                      ? _buildMediumScreenFilters(theme)
                      : _buildSmallScreenFilters(theme)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideScreenFilters(ThemeData theme) {
    return Column(
      children: [
        _buildFilterRow([
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Nom', 
            icon: Icons.store_mall_directory, 
            filterKey: 'nom'
          ),
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Adresse', 
            icon: Icons.location_on, 
            filterKey: 'adresse'
          ),
        
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactDropdown(
            theme: theme,
            label: 'Ville', 
            icon: Icons.map, 
            filterKey: 'ville',
            options: _villes,
          ),
  
        ]),
      ],
    );
  }

  Widget _buildMediumScreenFilters(ThemeData theme) {
    return Column(
      children: [
        _buildFilterRow([
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Nom', 
            icon: Icons.store_mall_directory, 
            filterKey: 'nom'
          ),
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Adresse', 
            icon: Icons.location_on, 
            filterKey: 'adresse'
          ),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
      
          _buildCompactDropdown(
            theme: theme,
            label: 'Ville', 
            icon: Icons.map, 
            filterKey: 'ville',
            options: _villes,
          ),
        ]),
      
      ],
    );
  }

  Widget _buildSmallScreenFilters(ThemeData theme) {
    return Column(
      children: [
        _buildCompactFilterTextField(
          theme: theme,
          label: 'Nom', 
          icon: Icons.store_mall_directory, 
          filterKey: 'nom'
        ),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
          theme: theme,
          label: 'Adresse', 
          icon: Icons.location_on, 
          filterKey: 'adresse'
        ),
        
        const SizedBox(height: 8),
        _buildCompactDropdown(
          theme: theme,
          label: 'Ville', 
          icon: Icons.map, 
          filterKey: 'ville',
          options: _villes,
        ),
      ],
    );
  }

  Widget _buildCompactFilterTextField({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required String filterKey,
    String? hintText,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: TextField(
        controller: TextEditingController(text: _filters[filterKey]),
        onChanged: (value) => _updateFilter(filterKey, value),
        maxLines: 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText ?? 'Filtrer par $label',
          prefixIcon: Icon(icon, size: 16, color: theme.primaryColor),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
        ),
      ),
    ));
  }

  Widget _buildCompactDropdown({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required String filterKey,
    required List<String> options,
  }) {
    String displayValue = _filters[filterKey]?.isNotEmpty == true 
        ? _filters[filterKey]!
        : options.first;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 16, color: theme.primaryColor),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: displayValue,
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != options.first) {
                _updateFilter(filterKey, value);
              } else {
                _updateFilter(filterKey, '');
              }
            },
            isExpanded: true,
            isDense: true,
          ),
        ),
      ),
    );
  }



  Widget _buildFilterRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map((child) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: child,
                ),
              ))
          .toList(),
    );
  }
}