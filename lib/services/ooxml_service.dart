import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

import 'package:scanpdf/shared/models/scan_document.dart';

class OoxmlService {
  const OoxmlService(this.resolvePath);

  final String Function(String) resolvePath;

  String _xml(String value) => const HtmlEscape(
    HtmlEscapeMode.element,
  ).convert(value).replaceAll('&#39;', '&apos;');

  Uint8List buildDocx(ScanDocument document) {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string('[Content_Types].xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>'''),
      )
      ..addFile(
        ArchiveFile.string('_rels/.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>'''),
      )
      ..addFile(
        ArchiveFile.string(
          'word/_rels/document.xml.rels',
          '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''',
        ),
      );
    final paragraphs = document.ocrText.trim().isEmpty
        ? ['No recognized text was available.']
        : document.ocrText.split('\n');
    final body = paragraphs
        .map(
          (line) =>
              '<w:p><w:r><w:t xml:space="preserve">${_xml(line)}</w:t></w:r></w:p>',
        )
        .join();
    archive
      ..addFile(
        ArchiveFile.string('word/document.xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>${_xml(document.title)}</w:t></w:r></w:p>
    $body
    <w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1080" w:right="1080" w:bottom="1080" w:left="1080"/></w:sectPr>
  </w:body>
</w:document>'''),
      )
      ..addFile(ArchiveFile.string('docProps/core.xml', _core(document.title)))
      ..addFile(
        ArchiveFile.string('docProps/app.xml', _app('Microsoft Office Word')),
      );
    return ZipEncoder().encodeBytes(archive);
  }

  Future<Uint8List> buildPptx(ScanDocument document) async {
    const slideWidth = 12192000;
    const slideHeight = 6858000;
    final archive = Archive();
    final overrides = StringBuffer();
    final slideIds = StringBuffer();
    final presentationRels = StringBuffer();
    for (var i = 0; i < document.pages.length; i++) {
      final n = i + 1;
      overrides.writeln(
        '<Override PartName="/ppt/slides/slide$n.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>',
      );
      slideIds.writeln('<p:sldId id="${255 + n}" r:id="rId${n + 2}"/>');
      presentationRels.writeln(
        '<Relationship Id="rId${n + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$n.xml"/>',
      );
      final bytes = await File(
        resolvePath(document.pages[i].processedFileName),
      ).readAsBytes();
      final decoded = img.decodeImage(bytes);
      var width = slideWidth;
      var height = slideHeight;
      var x = 0;
      var y = 0;
      if (decoded != null) {
        final scale =
            (slideWidth / decoded.width < slideHeight / decoded.height)
            ? slideWidth / decoded.width
            : slideHeight / decoded.height;
        width = (decoded.width * scale).round();
        height = (decoded.height * scale).round();
        x = ((slideWidth - width) / 2).round();
        y = ((slideHeight - height) / 2).round();
      }
      archive
        ..addFile(ArchiveFile.bytes('ppt/media/image$n.jpg', bytes))
        ..addFile(
          ArchiveFile.string(
            'ppt/slides/slide$n.xml',
            _slide(n, x, y, width, height),
          ),
        )
        ..addFile(
          ArchiveFile.string('ppt/slides/_rels/slide$n.xml.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image$n.jpg"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>'''),
        );
    }
    archive
      ..addFile(
        ArchiveFile.string('[Content_Types].xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="jpg" ContentType="image/jpeg"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
  <Override PartName="/ppt/presProps.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presProps+xml"/>
  <Override PartName="/ppt/viewProps.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.viewProps+xml"/>
  <Override PartName="/ppt/tableStyles.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.tableStyles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  $overrides
</Types>'''),
      )
      ..addFile(
        ArchiveFile.string('_rels/.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>'''),
      )
      ..addFile(
        ArchiveFile.string('ppt/presentation.xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>
  <p:sldIdLst>$slideIds</p:sldIdLst>
  <p:sldSz cx="$slideWidth" cy="$slideHeight" type="screen16x9"/><p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>'''),
      )
      ..addFile(
        ArchiveFile.string('ppt/_rels/presentation.xml.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
  $presentationRels
</Relationships>'''),
      )
      ..addFile(
        ArchiveFile.string('ppt/slideMasters/slideMaster1.xml', _slideMaster()),
      )
      ..addFile(
        ArchiveFile.string('ppt/slideMasters/_rels/slideMaster1.xml.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>'''),
      )
      ..addFile(
        ArchiveFile.string('ppt/slideLayouts/slideLayout1.xml', _slideLayout()),
      )
      ..addFile(
        ArchiveFile.string(
          'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
          '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/></Relationships>''',
        ),
      )
      ..addFile(ArchiveFile.string('ppt/theme/theme1.xml', _theme()))
      ..addFile(
        ArchiveFile.string(
          'ppt/presProps.xml',
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><p:presentationPr xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"/>',
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'ppt/viewProps.xml',
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><p:viewPr xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"/>',
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'ppt/tableStyles.xml',
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><a:tblStyleLst xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" def="{5C22544A-7EE6-4342-B048-85BDC9FD1C3A}"/>',
        ),
      )
      ..addFile(ArchiveFile.string('docProps/core.xml', _core(document.title)))
      ..addFile(
        ArchiveFile.string(
          'docProps/app.xml',
          _app('Microsoft Office PowerPoint'),
        ),
      );
    return ZipEncoder().encodeBytes(archive);
  }

  String _slide(int n, int x, int y, int cx, int cy) =>
      '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
  <p:pic><p:nvPicPr><p:cNvPr id="2" name="Scan page $n"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr><p:blipFill><a:blip r:embed="rId1"/><a:stretch><a:fillRect/></a:stretch></p:blipFill><p:spPr><a:xfrm><a:off x="$x" y="$y"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic>
  </p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';

  String _slideMaster() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld><p:clrMap accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" bg1="lt1" bg2="lt2" folHlink="folHlink" hlink="hlink" tx1="dk1" tx2="dk2"/><p:sldLayoutIdLst><p:sldLayoutId id="1" r:id="rId1"/></p:sldLayoutIdLst><p:txStyles><p:titleStyle/><p:bodyStyle/><p:otherStyle/></p:txStyles></p:sldMaster>''';

  String _slideLayout() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank"><p:cSld name="Blank"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>''';

  String _theme() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Scan PDF"><a:themeElements><a:clrScheme name="Scan PDF"><a:dk1><a:srgbClr val="1C1840"/></a:dk1><a:lt1><a:srgbClr val="FFFFFF"/></a:lt1><a:dk2><a:srgbClr val="26214F"/></a:dk2><a:lt2><a:srgbClr val="F4F2FA"/></a:lt2><a:accent1><a:srgbClr val="FF7A1A"/></a:accent1><a:accent2><a:srgbClr val="6B5DD3"/></a:accent2><a:accent3><a:srgbClr val="5AAE7D"/></a:accent3><a:accent4><a:srgbClr val="5A8DEE"/></a:accent4><a:accent5><a:srgbClr val="C85BDD"/></a:accent5><a:accent6><a:srgbClr val="F2C94C"/></a:accent6><a:hlink><a:srgbClr val="0563C1"/></a:hlink><a:folHlink><a:srgbClr val="954F72"/></a:folHlink></a:clrScheme><a:fontScheme name="Scan PDF"><a:majorFont><a:latin typeface="Archivo"/></a:majorFont><a:minorFont><a:latin typeface="Archivo"/></a:minorFont></a:fontScheme><a:fmtScheme name="Scan PDF"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="6350"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>''';

  String _core(String title) {
    final now = DateTime.now().toUtc().toIso8601String();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>${_xml(title)}</dc:title><dc:creator>Scan PDF</dc:creator><dcterms:created xsi:type="dcterms:W3CDTF">$now</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">$now</dcterms:modified></cp:coreProperties>''';
  }

  String _app(String application) =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>$application</Application><AppVersion>16.0000</AppVersion></Properties>''';
}
