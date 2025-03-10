import 'package:opti_app/domain/entities/Order.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:opti_app/Presentation/UI/screens/User/ordersList_screen.dart';

// Fonction principale pour générer et afficher la facture
Future<void> generateAndOpenInvoice(Order order) async {
  // Generate the PDF and get the file path
  final pdfPath = await _generateInvoice(order);

  // Ensure order.id is not null, otherwise provide a fallback
  final orderId = order.id?.toString() ?? 'unknown';

  // Navigate to PDF Viewer Screen
  Get.to(() => PdfViewerScreen(
        pdfPath: pdfPath,
        title: 'Invoice #$orderId',
        orderId: orderId,
        order: order, // Pass the entire order object
      ));
}

// PDF Viewer Screen with Order List Navigation
class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;
  final String title;
  final String orderId;
  final Order order; // Add order parameter

  const PdfViewerScreen({
    Key? key,
    required this.pdfPath,
    required this.title,
    required this.orderId,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // Button to view order list
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Voir toutes les commandes',
            onPressed: () {
              // Navigate to OrdersListPage
              Get.off(() => OrdersListPage());
            },
          ),
          // Download PDF button
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              downloadPdfFile(pdfPath, orderId);
            },
          ),
          // Share PDF button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(pdfPath)],
                  text: 'Your invoice #$orderId');
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        onRender: (_pages) {},
        onError: (error) {
          print(error.toString());
        },
        onPageError: (page, error) {
          print('$page: ${error.toString()}');
        },
        onViewCreated: (PDFViewController pdfViewController) {},
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to OrdersListPage
          Get.off(() => OrdersListPage());
        },
        icon: Icon(Icons.list),
        label: Text('Toutes les commandes'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// Fonction privée qui génère le PDF et retourne son chemin
Future<String> _generateInvoice(Order order) async {
  // Format de date français
  final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
  final formattedDate = dateFormat.format(order.createdAt);

  // Créer un document PDF
  final pdf = pw.Document();

  // Ajouter une page au PDF avec entête et pied de page
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => _buildHeader(order),
      footer: (context) => _buildFooter(context),
      build: (pw.Context context) {
        return [
          // Informations de la commande
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('COMMANDE #${order.id}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('Date: $formattedDate',
                          style: const pw.TextStyle(fontSize: 12)),
                    ]),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ADRESSE DE LIVRAISON:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.SizedBox(height: 5),
                        pw.Text(order.address,
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('MÉTHODE DE PAIEMENT:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.SizedBox(height: 5),
                        pw.Text(order.paymentMethod,
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Tableau des articles
          pw.Text('DÉTAIL DES ARTICLES',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildItemsTable(order),

          pw.SizedBox(height: 20),

          // Récapitulatif des prix
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 200,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPriceRow(
                      'Sous-total', '${order.subtotal.toStringAsFixed(2)} €'),
                  _buildPriceRow('Frais de livraison',
                      '${order.deliveryFee.toStringAsFixed(2)} €'),
                  pw.Divider(thickness: 1),
                  _buildPriceRow('TOTAL', '${order.total.toStringAsFixed(2)} €',
                      isTotal: true),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 30),

          // Message de remerciement
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Text('Merci pour votre commande !',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text('Pour toute question, contactez notre service client.',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
        ];
      },
    ),
  );

  // Sauvegarder le PDF dans un fichier temporaire
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/facture_${order.id}.pdf');
  await file.writeAsBytes(await pdf.save());

  // Retourner le chemin du fichier PDF
  return file.path;
}

// Construction de l'en-tête
pw.Widget _buildHeader(Order order) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 20),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('OPTI APP',
                style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black)),
            pw.SizedBox(height: 5),
            pw.Text('Votre partenaire optique',
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text('FACTURE',
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    ),
  );
}

// Construction du pied de page
pw.Widget _buildFooter(pw.Context context) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 20),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Opti App - SIRET: 123 456 789 00010',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        pw.Text('Page ${context.pageNumber} sur ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ),
  );
}

// Construction du tableau des articles
pw.Widget _buildItemsTable(Order order) {
  final headerStyle =
      pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white);
  final headerDecoration = const pw.BoxDecoration(color: PdfColors.grey800);

  return pw.Table(
    border: null,
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(2),
    },
    children: [
      // En-tête du tableau
      pw.TableRow(
        decoration: headerDecoration,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('Article',
                style: headerStyle, textAlign: pw.TextAlign.left),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('Prix unitaire',
                style: headerStyle, textAlign: pw.TextAlign.right),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('Qté',
                style: headerStyle, textAlign: pw.TextAlign.center),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('Total',
                style: headerStyle, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
      // Lignes d'articles
      ...order.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isEvenRow = index % 2 == 0;

        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEvenRow ? PdfColors.white : PdfColors.grey100,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(item.productName, textAlign: pw.TextAlign.left),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${item.unitPrice.toStringAsFixed(2)} €',
                  textAlign: pw.TextAlign.right),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child:
                  pw.Text('${item.quantity}', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${item.totalPrice.toStringAsFixed(2)} €',
                  textAlign: pw.TextAlign.right),
            ),
          ],
        );
      }).toList(),
    ],
  );
}

// Construction d'une ligne de prix
pw.Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: isTotal
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : const pw.TextStyle()),
        pw.Text(amount,
            style: isTotal
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : const pw.TextStyle()),
      ],
    ),
  );
}

Future<void> downloadPdfFile(String pdfPath, String orderId) async {
  try {
    Directory? destinationDirectory;

    if (Platform.isAndroid) {
      // Sur Android, on tente d'utiliser le dossier Download.
      destinationDirectory = Directory('/storage/emulated/0/Download');
      if (!await destinationDirectory.exists()) {
        // Fallback vers l'external storage de l'application.
        destinationDirectory = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      // Sur iOS, on utilise le dossier Documents.
      destinationDirectory = await getApplicationDocumentsDirectory();
    }

    if (destinationDirectory == null) {
      throw Exception("Aucun dossier de destination trouvé");
    }

    // Construire le nouveau chemin avec le nom de fichier souhaité.
    final newPath = "${destinationDirectory.path}/facture_$orderId.pdf";
    final sourceFile = File(pdfPath);
    await sourceFile.copy(newPath);

    Get.snackbar(
      "Téléchargement terminé",
      "Le fichier PDF a été sauvegardé dans: $newPath",
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (e) {
    Get.snackbar(
      "Erreur",
      "Impossible de télécharger le PDF: $e",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
