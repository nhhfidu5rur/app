import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExcelService {
  static Future<void> exportToExcel({
    required BuildContext context,
    required Map<String, dynamic> file,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = file['name'] ?? 'Sheet1';
    final Sheet sheet = excel[sheetName];

    // Remove default sheet
    excel.delete('Sheet1');

    final columns = List<String>.from(file['columns'] ?? []);
    final entries = List<dynamic>.from(file['entries'] ?? []);

    // Style - Header Row
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Headers: Date + Columns
    final headers = ['التاريخ', ...columns];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data Rows
    for (int rowIdx = 0; rowIdx < entries.length; rowIdx++) {
      final entry = Map<String, dynamic>.from(entries[rowIdx]);

      // Row style alternating
      final rowStyle = CellStyle(
        backgroundColorHex: rowIdx % 2 == 0
            ? ExcelColor.fromHexString('#EBF5FB')
            : ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Date cell
      final dateCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx + 1),
      );
      dateCell.value = TextCellValue(entry['date'] ?? '');
      dateCell.cellStyle = rowStyle;

      // Data cells
      for (int colIdx = 0; colIdx < columns.length; colIdx++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIdx + 1,
            rowIndex: rowIdx + 1,
          ),
        );
        cell.value = TextCellValue(entry[columns[colIdx]] ?? '');
        cell.cellStyle = rowStyle;
      }
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Save file
    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل في إنشاء الملف');

    final dir = await getTemporaryDirectory();
    final fileName =
        '${file['name']}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';
    final filePath = '${dir.path}/$fileName';

    final outputFile = File(filePath);
    await outputFile.writeAsBytes(bytes);

    // Share
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'ملف Excel: ${file['name']}',
      subject: fileName,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تصدير الملف بنجاح! 🎉'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
