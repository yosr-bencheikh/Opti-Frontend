import 'package:flutter/material.dart';

class FavoriteIcon extends StatefulWidget {
  @override
  _FavoriteIconState createState() => _FavoriteIconState();
}

class _FavoriteIconState extends State<FavoriteIcon> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.favorite,
        color: isFavorite ? Colors.red : Colors.grey, // Change la couleur
      ),
      onPressed: () {
        setState(() {
          isFavorite = !isFavorite; // Inverse l'état
        });
      },
    );
  }
}
