import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/note_model.dart';

class ExportService {
  static Future<void> exportNotesAsPdf(List<NoteModel> notes) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('KeyNote Chat History', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          ...notes.map((note) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(note.title ?? 'Untitled Note', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(note.createdAt.toString(), style: const pw.TextStyle(color: PdfColors.grey)),
                ],
              ),
              pw.SizedBox(height: 4),
              if (note.description != null) pw.Text(note.description!),
              if (note.imageUrl != null)
                pw.Text('[Image attached]', style: const pw.TextStyle(color: PdfColors.blue)),
              pw.Divider(),
              pw.SizedBox(height: 10),
            ],
          )),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
