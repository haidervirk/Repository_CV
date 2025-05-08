import 'package:flutter/material.dart';
import 'package:pmiuapp/widgets/footer.dart';

class Info extends StatelessWidget {
  const Info({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About us"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(8.0, 12, 8, 0),
              child: Text('PMIU-PESRP',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),),
            ),
        
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                width: double.infinity,
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25), // Adjust the value to your desired radius
                  child: Image.asset(
                    'assets/images/pmiu_pic.jpg',
                    fit: BoxFit.fill,
                  ),
                ),
              )
            ),
            
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text('Functioning as the think-tank and project implementation '
                  'wing of the School Education Department, the PMIU-PESRP is '
                  'mandated to strengthen and transform the educational '
                  'environment by providing equitable education service '
                  'delivery across the Punjab. Through a robust monitoring '
                  'and evaluation ecosystem, PMIU aims to bring constructive '
                  'and sustained change ensuring the provision of an unbounded'
                  ' environment to marginalized segments of society. PMIU’s '
                  'partnerships with policymakers, stakeholders, and '
                  'large-scale international donors enable productive and '
                  'effective interventions around access, quality, and governance'
                  ' of the education system in Punjab. \n \n \t '
                  'As the primary data hub for the School Education Department, '
                  'PMIU collect, compile, and analyze large datasets to identify gaps and '
                  'effectively utilize the research to inform evidence-based decision-making'
                  ' at multiple levels of management. It works to strengthen educational '
                  'governance through the employment of strategic initiatives that include '
                  'increasing enrollment and retention, improving classroom infrastructure '
                  'to provide a conducive learning environment, strengthening early years'
                  ' education, and increasing '
                  'learning levels of all children through sustainable and scalable reforms.'
                  '\n \n \t PMIU-PESRP enjoys unique operational flexibility'
                  ' allowing it to be responsive to vital needs in a quick and '
                  'effective manner. Equipped with a young and vibrant workforce, '
                  'the PMIU-PESRP specializes in designing and implementing out-of'
                  '-the-box solutions to complex education service delivery'
                  ' challenges. Having implemented multiple large-scale education '
                  'sector reform programmes funded by the World Bank, UK Foreign '
                  'Commonwealth and Development Office, and Global Partnership for'
                  ' Education among other donors, the PMIU-PESRP provides a dynamic'
                  ' one-stop solution to multiple education-centric issues'

              ),
            ),
            const Footer(),
          ],

        ),
      )
    );
  }
}
