import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';
import 'package:http/http.dart' as http;

class PdfService {
  static Future<void> generateAgencyDetailsPdf(AgencyModel agency) async {
    final pdf = pw.Document();

    // Load logo if available
    pw.ImageProvider? logoImage;
    if (agency.logoUrl != null && agency.logoUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(agency.logoUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        // Fallback or ignore
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Détails de l\'Agence',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const pw.TextStyle(color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      height: 80,
                      width: 80,
                      child: pw.Image(logoImage),
                    ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Divider(color: PdfColors.teal),
              pw.SizedBox(height: 24),

              // Informations Générales
              _buildSectionTitle('Informations Générales'),
              _buildInfoRow('Nom de l\'agence', agency.name),
              _buildInfoRow('Type de média', agency.mediaType.name),
              _buildInfoRow('Statut', agency.status.name.toUpperCase()),
              pw.SizedBox(height: 24),

              // Contact
              _buildSectionTitle('Contact'),
              _buildInfoRow('Email officiel', agency.email),
              _buildInfoRow('Site web', agency.websiteUrl ?? 'N/A'),
              pw.SizedBox(height: 24),

              // Documents / Description
              _buildSectionTitle('Documents & Description'),
              pw.Text(
                agency.rejectReason != null && agency.rejectReason!.isNotEmpty
                    ? 'Raison du rejet : ${agency.rejectReason}'
                    : 'Aucune information supplémentaire fournie.',
                style: const pw.TextStyle(fontSize: 12),
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Mr-News — Portail de Gestion Admin',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'agency_${agency.name}.pdf',
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.teal,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label :',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }
}
