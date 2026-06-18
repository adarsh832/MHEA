import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/pdf_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MandapAssociationApp());
}

class MandapAssociationApp extends StatelessWidget {
  const MandapAssociationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MHEA Vadodara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          surface: const Color(0xFFFDFCFB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          prefixIconColor: const Color(0xFF1E3A8A),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 16),
        ),
      ),
      home: const RegistrationFormPage(),
    );
  }
}

// --- FORM 1: REGISTRATION ---
class RegistrationFormPage extends StatefulWidget {
  const RegistrationFormPage({super.key});

  @override
  State<RegistrationFormPage> createState() => _RegistrationFormPageState();
}

class _RegistrationFormPageState extends State<RegistrationFormPage> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {
    'psk_number': TextEditingController(),
    'taluka': TextEditingController(),
    'district': TextEditingController(),
    'firm_name': TextEditingController(),
    'firm_address': TextEditingController(),
    'name': TextEditingController(),
    'home_address': TextEditingController(),
    'mobile_no': TextEditingController(),
    'whatsapp_no': TextEditingController(),
    'dob': TextEditingController(),
    'aadhaar_no': TextEditingController(),
    'blood_group': TextEditingController(),
    'pan_no': TextEditingController(),
    'registration_no': TextEditingController(),
    'firm_start_date': TextEditingController(),
    'gst_no': TextEditingController(),
    'msme_no': TextEditingController(),
  };

  File? idPhoto1;
  File? idPhoto2;
  File? userPhoto;
  bool _isLoading = false;
  final PdfApiService _apiService = PdfApiService();

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _handlePdfGeneration() async {
    if (idPhoto1 == null || idPhoto2 == null || userPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("કૃપા કરીને બધા ફોટા અને ID અપલોડ કરો")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, String> formData = {
        "psk_number": _controllers['psk_number']!.text,
        "district": _controllers['district']!.text,
        "taluko": _controllers['taluka']!.text,
        "shop_name": _controllers['firm_name']!.text,
        "shop_address": _controllers['firm_address']!.text,
        "owner_name": _controllers['name']!.text,
        "home_address": _controllers['home_address']!.text,
        "mobile_number": _controllers['mobile_no']!.text,
        "whatsapp_number": _controllers['whatsapp_no']!.text,
        "birth_date": _controllers['dob']!.text,
        "registration_date": _controllers['firm_start_date']!.text,
        "blood_group": _controllers['blood_group']!.text,
        "aadhar_number": _controllers['aadhaar_no']!.text,
        "pan_number": _controllers['pan_no']!.text,
        "gst_number": _controllers['gst_no']!.text,
        "registration_number": _controllers['registration_no']!.text,
        "msme_number": _controllers['msme_no']!.text,
      };

      final pdfBytes = await _apiService.generatePdf(formData, {
        "idPhoto1": idPhoto1!,
        "idPhoto2": idPhoto2!,
        "userPhoto": userPhoto!,
      });
      
      if (pdfBytes != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SecondaryFormPage(
              registrationPdf: pdfBytes,
              initialData: formData,
              idPhoto1: idPhoto1!,
              idPhoto2: idPhoto2!,
            ),
          ),
        );
      }
    } catch (e) {
      String userMessage = "કંઈક ખોટું થયું છે. કૃપા કરીને ફરી પ્રયાસ કરો. (Something went wrong)";
      if (e.toString().contains("Failed to generate PDF")) {
        userMessage = "સર્વર અત્યારે વ્યસ્ત છે. કૃપા કરીને થોડી વાર પછી પ્રયત્ન કરો. (Server Busy)";
      } else if (e.toString().contains("SocketException")) {
        userMessage = "તમારું ઇન્ટરનેટ કનેક્શન તપાસો. (Check Internet Connection)";
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userMessage), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("સભાસદ અરજી (Form 1)"), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const FormHeader(),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: TopMetaFields(pskController: _controllers['psk_number']!, talukaController: _controllers['taluka']!, districtController: _controllers['district']!)),
                          const SizedBox(width: 12),
                          Expanded(flex: 1, child: ImagePickerBox(label: "અરજદારનો ફોટો", height: 120, onImageSelected: (f) => userPhoto = f)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: "પેઢીની માહિતી (Basic Info)"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomTextField(label: "પેઢીનું નામ :", controller: _controllers['firm_name']!, prefixIcon: Icons.business),
                      CustomTextField(label: "પેઢીનું સરનામું :", maxLines: 2, controller: _controllers['firm_address']!, prefixIcon: Icons.location_city),
                      CustomTextField(label: "માલીકનું નામ :", controller: _controllers['name']!, prefixIcon: Icons.person),
                      CustomTextField(label: "ઘરનું સરનામું :", maxLines: 2, controller: _controllers['home_address']!, prefixIcon: Icons.home),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: "સંપર્ક માહિતી (Contact)"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(child: CustomTextField(label: "મોબાઇલ નં:", controller: _controllers['mobile_no']!, prefixIcon: Icons.phone_android, keyboardType: TextInputType.phone)),
                      const SizedBox(width: 12),
                      Expanded(child: CustomTextField(label: "વોટ્સએપ નં:", controller: _controllers['whatsapp_no']!, prefixIcon: Icons.chat, keyboardType: TextInputType.phone)),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: "વ્યક્તિગત વિગત (Personal)"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: CustomTextField(label: "જન્મ તારીખ:", controller: _controllers['dob']!, prefixIcon: Icons.cake, readOnly: true, onTap: () => _selectDate(context, _controllers['dob']!))),
                          const SizedBox(width: 12),
                          Expanded(child: CustomTextField(label: "આધારકાર્ડ:", controller: _controllers['aadhaar_no']!, prefixIcon: Icons.badge, keyboardType: TextInputType.number)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: CustomTextField(label: "બ્લડ ગ્રુપ:", controller: _controllers['blood_group']!, prefixIcon: Icons.bloodtype)),
                          const SizedBox(width: 12),
                          Expanded(child: CustomTextField(label: "પાન કાર્ડ:", controller: _controllers['pan_no']!, prefixIcon: Icons.credit_card)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: "નોંધણી વિગત (Registration)"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: CustomTextField(label: "નોંધણી નંબર:", controller: _controllers['registration_no']!, prefixIcon: Icons.app_registration)),
                          const SizedBox(width: 12),
                          Expanded(child: CustomTextField(label: "શરૂ કર્યા તારીખ:", controller: _controllers['firm_start_date']!, prefixIcon: Icons.calendar_today, readOnly: true, onTap: () => _selectDate(context, _controllers['firm_start_date']!))),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: CustomTextField(label: "GST. નંબર:", controller: _controllers['gst_no']!, prefixIcon: Icons.receipt_long)),
                          const SizedBox(width: 12),
                          Expanded(child: CustomTextField(label: "MSME નંબર:", controller: _controllers['msme_no']!, prefixIcon: Icons.assignment)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: "Digital ID Photos"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(child: ImagePickerBox(label: "ID Photo 1", onImageSelected: (f) => idPhoto1 = f)),
                      const SizedBox(width: 12),
                      Expanded(child: ImagePickerBox(label: "ID Photo 2", onImageSelected: (f) => idPhoto2 = f)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handlePdfGeneration(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("આગળ વધો (Continue to Insurance Form)"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- FORM 2: INSURANCE ---
class SecondaryFormPage extends StatefulWidget {
  final Uint8List registrationPdf;
  final Map<String, String> initialData;
  final File idPhoto1;
  final File idPhoto2;

  const SecondaryFormPage({
    super.key,
    required this.registrationPdf,
    required this.initialData,
    required this.idPhoto1,
    required this.idPhoto2,
  });

  @override
  State<SecondaryFormPage> createState() => _SecondaryFormPageState();
}

class _SecondaryFormPageState extends State<SecondaryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = false;
  final PdfApiService _apiService = PdfApiService();

  @override
  void initState() {
    super.initState();
    _controllers = {
      'shop_name': TextEditingController(text: widget.initialData['shop_name']),
      'owner_name': TextEditingController(text: widget.initialData['owner_name']),
      'birth_date': TextEditingController(text: widget.initialData['birth_date']),
      'age': TextEditingController(),
      'blood_group': TextEditingController(text: widget.initialData['blood_group']),
      'home_address': TextEditingController(text: widget.initialData['home_address']),
      'village': TextEditingController(),
      'taluko': TextEditingController(text: widget.initialData['taluko']),
      'district': TextEditingController(text: widget.initialData['district']),
      'pincode': TextEditingController(),
      'mobile_number': TextEditingController(text: widget.initialData['mobile_number']),
      'email': TextEditingController(),
      'whatsapp_number': TextEditingController(text: widget.initialData['whatsapp_number']),
      'nominee_name': TextEditingController(),
      'nominee_birth_date': TextEditingController(),
      'nominee_age': TextEditingController(),
      'nominee_relation': TextEditingController(),
      'receipt_number': TextEditingController(),
      'receipt_date': TextEditingController(),
    };
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _handleInsurancePdf() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, String> formData = _controllers.map((key, value) => MapEntry(key, value.text));
      
      final pdfBytes = await _apiService.generatePdf(
        formData,
        {"idPhoto1": widget.idPhoto1, "idPhoto2": widget.idPhoto2},
        templateName: "form-2.html",
      );

      if (pdfBytes != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinalSuccessPage(
              registrationPdf: widget.registrationPdf,
              insurancePdf: pdfBytes,
              pskNumber: widget.initialData['psk_number'] ?? "000",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("વિમા સંમતિપત્ર (Insurance Form)"), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SectionHeader(title: "વિમેદાર વેપારીની વિગત (Auto-filled)"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomTextField(label: "પેઢીનું નામ :", controller: _controllers['shop_name']!),
                      CustomTextField(label: "વેપારીનું પૂરું નામ :", controller: _controllers['owner_name']!),
                      Row(
                        children: [
                          Expanded(child: CustomTextField(label: "જન્મ તારીખ :", controller: _controllers['birth_date']!, readOnly: true)),
                          const SizedBox(width: 12),
                          Expanded(child: CustomTextField(label: "ઉંમર વર્ષ :", controller: _controllers['age']!, keyboardType: TextInputType.number)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: "સરનામું અને સંપર્ક (Address)"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomTextField(label: "ગામ :", controller: _controllers['village']!),
                      Row(
                        children: [
                          Expanded(child: CustomTextField(label: "તાલુકો :", controller: _controllers['taluko']!)),
                          const SizedBox(width: 12),
                          Expanded(child: CustomTextField(label: "જીલ્લો :", controller: _controllers['district']!)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: CustomTextField(label: "પીનકોડ :", controller: _controllers['pincode']!, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: CustomTextField(label: "ઇ-મેઇલ :", controller: _controllers['email']!, keyboardType: TextInputType.emailAddress)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: "વારસદારની વિગત (Nominee)"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomTextField(label: "વારસદારનું નામ :", controller: _controllers['nominee_name']!),
                      Row(
                        children: [
                          Expanded(child: CustomTextField(label: "જન્મ તારીખ :", controller: _controllers['nominee_birth_date']!, readOnly: true, onTap: () => _selectDate(context, _controllers['nominee_birth_date']!))),
                          const SizedBox(width: 12),
                          Expanded(child: CustomTextField(label: "ઉંમર વર્ષ :", controller: _controllers['nominee_age']!, keyboardType: TextInputType.number)),
                        ],
                      ),
                      CustomTextField(label: "સંબંધ :", controller: _controllers['nominee_relation']!),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: "પહોંચ વિગત (Receipt)"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(child: CustomTextField(label: "પહોંચ નંબર :", controller: _controllers['receipt_number']!)),
                      const SizedBox(width: 12),
                      Expanded(child: CustomTextField(label: "તારીખ :", controller: _controllers['receipt_date']!, readOnly: true, onTap: () => _selectDate(context, _controllers['receipt_date']!))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleInsurancePdf(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ફોર્મ સબમિટ કરો (Final Submit)"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- FINAL SUCCESS & PREVIEW PAGE ---
class FinalSuccessPage extends StatelessWidget {
  final Uint8List registrationPdf;
  final Uint8List insurancePdf;
  final String pskNumber;

  const FinalSuccessPage({
    super.key,
    required this.registrationPdf,
    required this.insurancePdf,
    required this.pskNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("સબમિશન સફળ (Success)"), automaticallyImplyLeading: false, backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text("અરજી સફળતાપૂર્વક સબમિટ થઈ ગઈ છે!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              const Text("તમારા PDF ડાઉનલોડ કરવા અથવા જોવા માટે નીચે ક્લિક કરો:", textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _PdfButton(
                label: "સભાસદ અરજી (Registration PDF)",
                icon: Icons.description,
                color: const Color(0xFF1E3A8A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewerPage(pdfBytes: registrationPdf, fileName: "Registration_$pskNumber.pdf"))),
              ),
              const SizedBox(height: 12),
              _PdfButton(
                label: "વિમા સંમતિપત્ર (Insurance PDF)",
                icon: Icons.health_and_safety,
                color: const Color(0xFFC2185B),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewerPage(pdfBytes: insurancePdf, fileName: "Insurance_$pskNumber.pdf"))),
              ),
              const SizedBox(height: 40),
              TextButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home),
                label: const Text("મુખ્ય પૃષ્ઠ પર પાછા જાઓ (Back to Home)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PdfButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}

// --- SUPPORTING WIDGETS ---
class PdfViewerPage extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const PdfViewerPage({super.key, required this.pdfBytes, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Preview"), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: PdfPreview(
        build: (format) => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: fileName,
      ),
    );
  }
}

class FormHeader extends StatelessWidget {
  const FormHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
            child: ClipOval(child: Padding(padding: const EdgeInsets.all(12.0), child: Image.asset('images/app_logo.jpeg', fit: BoxFit.contain))),
          ),
        ),
        const SizedBox(height: 12),
        const Text("મંડપ હાયરર્સ ઇલેક્ટ્રિકલ એસોશિએશન", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8, top: 16), child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)));
  }
}

class ImagePickerBox extends StatefulWidget {
  final String label;
  final double height;
  final Function(File) onImageSelected;
  const ImagePickerBox({super.key, required this.label, this.height = 120, required this.onImageSelected});
  @override
  State<ImagePickerBox> createState() => _ImagePickerBoxState();
}

class _ImagePickerBoxState extends State<ImagePickerBox> {
  File? _image;
  final _picker = ImagePicker();
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() { _image = File(pickedFile.path); widget.onImageSelected(_image!); });
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _image == null 
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_a_photo_outlined, color: Color(0xFF1E3A8A)), Text(widget.label, style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)))])
            : Image.file(_image!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class TopMetaFields extends StatelessWidget {
  final TextEditingController pskController;
  final TextEditingController talukaController;
  final TextEditingController districtController;
  const TopMetaFields({super.key, required this.pskController, required this.talukaController, required this.districtController});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [Expanded(child: CustomTextField(label: "PSK-નંબર:", controller: pskController, isDense: true)), const SizedBox(width: 8), Expanded(child: CustomTextField(label: "તાલુકો:", controller: talukaController, isDense: true))]),
      CustomTextField(label: "જીલ્લો:", controller: districtController, isDense: true),
    ]);
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final int maxLines;
  final bool isDense;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  const CustomTextField({super.key, required this.label, this.maxLines = 1, this.isDense = false, required this.controller, this.prefixIcon, this.keyboardType, this.readOnly = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(labelText: label, isDense: isDense, prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null),
      ),
    );
  }
}
