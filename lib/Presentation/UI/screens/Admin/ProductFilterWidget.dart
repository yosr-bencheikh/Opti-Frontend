import 'package:flutter/material.dart';

class ProductFilterWidget extends StatefulWidget {
  final Map<String, String> initialFilters;
  final Function(Map<String, String>) onFilterChanged;
  
  const ProductFilterWidget({
    Key? key, 
    required this.onFilterChanged,
    required this.initialFilters,
  }) : super(key: key);

  @override
  _ProductFilterWidgetState createState() => _ProductFilterWidgetState();
}

class _ProductFilterWidgetState extends State<ProductFilterWidget> {
  late Map<String, String> _filters;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters);
    _minPriceController.text = _filters['minPrice'] ?? '';
    _maxPriceController.text = _filters['maxPrice'] ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

void _updateFilter(String key, String value) {
  setState(() {
    _filters[key] = value;
    // Ajouter une logique pour gérer les cas spéciaux
    if (key == 'categorie' && value == 'Toutes catégories') {
      _filters[key] = '';
    }
    if (key == 'marque' && value == 'Toutes marques') {
      _filters[key] = '';
    }
    if (key == 'typesVerre' && value == 'Toutes typesVerre') {
      _filters[key] = '';
    }
    if (key == 'boutique' && value == 'Toutes les boutiques') {
      _filters[key] = '';
    }
    widget.onFilterChanged(_filters);
  });
}

  void _resetFilters() {
    setState(() {
      _filters = {
        'nom': '',
        'boutique': '',
        'categorie': '',
        'marque': '',
        'couleur': '',
        'minPrice': '',
        'maxPrice': '',
      };
      _minPriceController.clear();
      _maxPriceController.clear();
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
      height: isWideScreen ? 220 : (isMediumScreen ? 300 : 400),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
      )],
        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: theme.primaryColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'Filtres Produits',
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
            icon: Icons.label, 
            filterKey: 'nom'
          ),
      
        
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactDropdown(
            theme: theme,
            label: 'Catégorie', 
            icon: Icons.category, 
            filterKey: 'categorie',
            options: ['Toutes catégories','Solaire',
  'Vue',
  'Sport',
  'Lecture',
  'Enfant',
  'Luxe',
  'Tendance',
  'Protection'], // À remplacer
          ),
              _buildCompactDropdown(
            theme: theme,
            label: 'typesVerre', 
            icon: Icons.branding_watermark, 
            filterKey: 'typesVerre',
            options: ['Toutes typesVerre',  'Simple',
  'Progressif',
  'Bifocal',
  'Photochromique',
  'Antireflet',
  'Polarisé',
  'Anti-lumière bleue'], // À remplacer
          ),
          _buildCompactDropdown(
            theme: theme,
            label: 'Marque', 
            icon: Icons.branding_watermark, 
            filterKey: 'marque',
            options: ['Toutes marques',  'Ray-Ban',
  'Oakley',
  'Gucci',
  'Prada',
  'Dior',
  'Chanel',
  'Versace',
  'Tom Ford',
  'Persol',
  'Carrera'], // À remplacer
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
            icon: Icons.label, 
            filterKey: 'nom'
          ),
          _buildCompactDropdown(
            theme: theme,
            label: 'Boutique', 
            icon: Icons.store, 
            filterKey: 'boutique',
            options: ['Toutes les boutiques', 'Boutique 1', 'Boutique 2'],
          ),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactDropdown(
            theme: theme,
            label: 'Catégorie', 
            icon: Icons.category, 
            filterKey: 'categorie',
            options: ['Toutes catégories', 'Lunettes', 'Lentilles'],
          ),
          _buildCompactDropdown(
            theme: theme,
            label: 'Marque', 
            icon: Icons.branding_watermark, 
            filterKey: 'marque',
            options: ['Toutes marques', 'Ray-Ban', 'Oakley'],
          ),
        ]),
        const SizedBox(height: 12),
        _buildPriceRangeFilter(theme, isFullWidth: true),
      ],
    );
  }

  Widget _buildSmallScreenFilters(ThemeData theme) {
    return Column(
      children: [
        _buildCompactFilterTextField(
          theme: theme,
          label: 'Nom', 
          icon: Icons.label, 
          filterKey: 'nom'
        ),
        const SizedBox(height: 8),
        _buildCompactDropdown(
          theme: theme,
          label: 'Boutique', 
          icon: Icons.store, 
          filterKey: 'boutique',
          options: ['Toutes les boutiques', 'Boutique 1', 'Boutique 2'],
        ),
        const SizedBox(height: 8),
        _buildCompactDropdown(
          theme: theme,
          label: 'Catégorie', 
          icon: Icons.category, 
          filterKey: 'categorie',
          options: ['Toutes catégories', 'Lunettes', 'Lentilles'],
        ),
        const SizedBox(height: 8),
        _buildCompactDropdown(
          theme: theme,
          label: 'Marque', 
          icon: Icons.branding_watermark, 
          filterKey: 'marque',
          options: ['Toutes marques', 'Ray-Ban', 'Oakley'],
        ),
        const SizedBox(height: 8),
        _buildPriceRangeFilter(theme, isFullWidth: true),
      ],
    );
  }

  Widget _buildPriceRangeFilter(ThemeData theme, {bool isFullWidth = false}) {
    return isFullWidth 
      ? Column(
          children: [
            const Text('Plage de prix', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildPriceTextField(
                    theme: theme,
                    label: 'Min',
                    controller: _minPriceController,
                    onChanged: (value) => _updateFilter('minPrice', value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPriceTextField(
                    theme: theme,
                    label: 'Max',
                    controller: _maxPriceController,
                    onChanged: (value) => _updateFilter('maxPrice', value),
                  ),
                ),
              ],
            ),
          ],
        )
      : Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Plage de prix', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceTextField(
                      theme: theme,
                      label: 'Min',
                      controller: _minPriceController,
                      onChanged: (value) => _updateFilter('minPrice', value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPriceTextField(
                      theme: theme,
                      label: 'Max',
                      controller: _maxPriceController,
                      onChanged: (value) => _updateFilter('maxPrice', value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
  }

  Widget _buildPriceTextField({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.attach_money, size: 16, color: theme.primaryColor),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 12),
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
      ),
    );
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
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
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

class TableColumn {
  final int flex;
  final String label;
  final IconData icon;
  final bool isActions;

  TableColumn({
    required this.flex,
    required this.label,
    required this.icon,
    this.isActions = false,
  });
}