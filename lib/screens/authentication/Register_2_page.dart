// ignore_for_file: file_names

import 'package:becapy/helper/utils/validator.dart';
import 'package:becapy/widgets/text_field_widget.dart';
import 'package:flutter/cupertino.dart';

class Register2 extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController nameController;
  const Register2({
    required this.firstNameController,
    required this.lastNameController,
    required this.nameController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFieldWidget(
                  editingController: firstNameController,
                  textCapitalization: TextCapitalization.words,
                  label: "First Name",
                  validatorHandler: (val) =>
                      Validator.validateAuthFields(result: val.trim()),
                  inputType: TextInputType.name,
                  icon: CupertinoIcons.person_alt,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextFieldWidget(
                  editingController: lastNameController,
                  textCapitalization: TextCapitalization.words,
                  label: "Last Name",
                  validatorHandler: (val) =>
                      Validator.validateAuthFields(result: val.trim()),
                  inputType: TextInputType.name,
                  icon: CupertinoIcons.person_alt,
                ),
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          TextFieldWidget(
            editingController: nameController,
            textCapitalization: TextCapitalization.none,
            label: "Username",
            validatorHandler: (val) =>
                Validator.validateAuthFields(result: val.trim()),
            inputType: TextInputType.name,
            icon: CupertinoIcons.at_circle,
          ),
        ],
      ),
    );
  }
}
