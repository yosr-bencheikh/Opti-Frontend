import 'package:flutter/material.dart';

class OpticianFilterWidget extends StatefulWidget {
  final Map<String, String> initialFilters;
  final Function(Map<String, String>) onFilterChanged;
  
  const OpticianFilterWidget({
    Key? key, 
    required this.onFilterChanged,
    required this.initialFilters,
  }) : super(key: key);

  @override
  _OpticianFilterWidgetState createState() => _OpticianFilterWidgetState();
}

class _OpticianFilterWidgetState extends State<OpticianFilterWidget> {
  late Map<String, String> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters);
  }
  
  final List<String> _regions = [
    'Toutes les régions',
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
        'prenom': '',
        'email': '',
        'phone': '',
        'date': '',
        'region': '',
        'genre': '',
      };
      widget.onFilterChanged(_filters);
    });
  }

  // Make sure the filter widget handles height constraints properly
 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    final isMediumScreen = MediaQuery.of(context).size.width > 600;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
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
        border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1),
      ),
      // Au lieu d'un ConstrainedBox + SingleChildScrollView, utilisons une hauteur fixe raisonnable
      height: isWideScreen ? 200 : (isMediumScreen ? 280 : 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: theme.primaryColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'Filtres Opticiens',
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

          // Utiliser Expanded pour que le contenu des filtres prenne l'espace disponible
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
            icon: Icons.person, 
            filterKey: 'nom'
          ),
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Prénom', 
            icon: Icons.person_outline, 
            filterKey: 'prenom'
          ),
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Email', 
            icon: Icons.email_outlined, 
            filterKey: 'email'
          ),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Téléphone', 
            icon: Icons.phone_outlined, 
            filterKey: 'phone'
          ),
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Date', 
            hintText: 'YYYY-MM-DD', 
            icon: Icons.calendar_today, 
            filterKey: 'date'
          ),
          _buildCompactDropdown(
            theme: theme,
            label: 'Région', 
            icon: Icons.location_on_outlined, 
            filterKey: 'region'
          ),
          _buildCompactDropdown(
            theme: theme,
            label: 'Genre', 
            icon: Icons.people_outline, 
            filterKey: 'genre'
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
            icon: Icons.person, 
            filterKey: 'nom'
          ),
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Prénom', 
            icon: Icons.person_outline, 
            filterKey: 'prenom'
          ),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Email', 
            icon: Icons.email_outlined, 
            filterKey: 'email'
          ),
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Téléphone', 
            icon: Icons.phone_outlined, 
            filterKey: 'phone'
          ),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactFilterTextField(
            theme: theme,
            label: 'Date', 
            hintText: 'YYYY-MM-DD', 
            icon: Icons.calendar_today, 
            filterKey: 'date'
          ),
          _buildCompactDropdown(
            theme: theme,
            label: 'Région', 
            icon: Icons.location_on_outlined, 
            filterKey: 'region'
          ),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactDropdown(
            theme: theme,
            label: 'Genre', 
            icon: Icons.people_outline, 
            filterKey: 'genre'
          ),
          const Spacer(),
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
          icon: Icons.person, 
          filterKey: 'nom'
        ),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
          theme: theme,
          label: 'Prénom', 
          icon: Icons.person_outline, 
          filterKey: 'prenom'
        ),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
          theme: theme,
          label: 'Email', 
          icon: Icons.email_outlined, 
          filterKey: 'email'
        ),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
          theme: theme,
          label: 'Téléphone', 
          icon: Icons.phone_outlined, 
          filterKey: 'phone'
        ),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
          theme: theme,
          label: 'Date', 
          hintText: 'YYYY-MM-DD', 
          icon: Icons.calendar_today, 
          filterKey: 'date'
        ),
        const SizedBox(height: 8),
        _buildCompactDropdown(
          theme: theme,
          label: 'Région', 
          icon: Icons.location_on_outlined, 
          filterKey: 'region'
        ),
        const SizedBox(height: 8),
        _buildCompactDropdown(
          theme: theme,
          label: 'Genre', 
          icon: Icons.people_outline, 
          filterKey: 'genre'
        ),
      ],
    );
  }

  // For the filter inputs, you can add a maxLines: 1 property to avoid overflow
  Widget _buildCompactFilterTextField({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required String filterKey,
    String? hintText,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50), // Reduced from 60
      child: TextField(
        controller: TextEditingController(text: _filters[filterKey]),
        onChanged: (value) => _updateFilter(filterKey, value),
        maxLines: 1, // Prevent multi-line input
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText ?? 'Filtrer par $label',
          prefixIcon: Icon(icon, size: 16, color: theme.primaryColor),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.primaryColor),
          ),
          isDense: true,
          labelStyle: TextStyle(color: theme.hintColor),
        ),
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      ),
    );
  }

  Widget _buildCompactDropdown({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required String filterKey,
  }) {
    List<String> options = filterKey == 'region' 
        ? _regions
        : ['Tous les genres', 'Homme', 'Femme'];
    
    String displayValue = _filters[filterKey] ?? '';
    if (displayValue.isEmpty) {
      displayValue = filterKey == 'region' ? 'Toutes les régions' : 'Tous les genres';
    }
    
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 16, color: theme.primaryColor),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.primaryColor),
          ),
          isDense: true,
          labelStyle: TextStyle(color: theme.hintColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: displayValue,
            items: filterKey == 'region' 
                ? _buildRegionDropdownItems(theme)
                : _buildGenderDropdownItems(theme),
            onChanged: (value) {
              if (value != null) {
                _updateFilter(filterKey, value);
              }
            },
            isExpanded: true,
            isDense: true,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
            ),
            dropdownColor: theme.cardColor,
            icon: Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildRegionDropdownItems(ThemeData theme) {
    return [
      DropdownMenuItem<String>(
        value: 'Toutes les régions',
        child: Text('Toutes les régions', style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
        )),
      ),
      ..._regions.where((r) => r != 'Toutes les régions').map((region) {
        return DropdownMenuItem<String>(
          value: region,
          child: Text(region, style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
          )),
        );
      }).toList(),
    ];
  }

  List<DropdownMenuItem<String>> _buildGenderDropdownItems(ThemeData theme) {
    return [
      DropdownMenuItem<String>(
        value: 'Tous les genres',
        child: Text('Tous les genres', style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
        )),
      ),
      ...['Homme', 'Femme'].map((genre) {
        return DropdownMenuItem<String>(
          value: genre,
          child: Text(genre, style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
          )),
        );
      }).toList(),
    ];
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