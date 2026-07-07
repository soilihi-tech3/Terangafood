import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/order_history_service.dart';

class PdfService {
  static Future<void> generateAndPrintReceipt(HistoryOrder order, List<Map<String, dynamic>> parsedItems) async {
    final pdf = pw.Document();

    final deliveryFee = order.deliveryMethod == "moto" ? 800.0 : (order.deliveryMethod == "voiture" ? 1500.0 : 0.0);
    final subtotal = order.total - deliveryFee;

    final payMethodStr = order.paymentMethod == "wave"
        ? "Wave 🟦"
        : (order.paymentMethod == "omoney" ? "Orange Money 🟧" : "Espèces (Cash) 💵");

    final methodStr = order.deliveryMethod == "moto"
        ? "Livreur à Moto 🛵"
        : (order.deliveryMethod == "voiture" ? "Livreur en Voiture 🚗" : "Retrait au Restaurant 🏪");

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Restaurant Info
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "TERANGAFOOD",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex("#E8612C"),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Le vrai goût de la Teranga",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "Dakar, Sénégal · Tel: +221 77 261 38 81",
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // Order Summary Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "REÇU DE COMMANDE",
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text("ID: ${order.id}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text("Date: ${order.date}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Statut:", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(
                        order.status == "livree" ? "LIVRÉE" : "EN COURS",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: order.status == "livree" ? PdfColors.green700 : PdfColors.orange700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Items table
              pw.Text("Articles", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: pw.Text("Nom", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: pw.Text("Qté", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: pw.Text("Prix", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Table Content
                  ...parsedItems.map((p) {
                    final item = p['item'];
                    final price = item != null ? (item.price * p['quantity']) : 0.0;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                          child: pw.Text(p['name'] as String, style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                          child: pw.Text("${p['quantity']}", style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                          child: pw.Text("${price.toStringAsFixed(0)} F", style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),

              // Total block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Paiement: $payMethodStr", style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("Livraison: $methodStr", style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("Dest: ${order.destination}", style: const pw.TextStyle(fontSize: 8), maxLines: 1),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Sous-total: ${subtotal.toStringAsFixed(0)} F", style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("Livraison: ${deliveryFee.toStringAsFixed(0)} F", style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Total: ${order.total.toStringAsFixed(0)} F",
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#E8612C")),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "Jërëjëf ! Merci pour votre confiance.",
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "TerangaFood - Bon Appétit !",
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "recu_commande_${order.id}.pdf",
    );
  }
}
