import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  String _getTermsContent(String language) {
    switch (language) {
      case 'ko':
        return '''
YONSEI BRIDGE 이용약관

제1조 (목적)
본 약관은 YONSEI BRIDGE(이하 "서비스")가 제공하는 모든 서비스의 이용 조건 및 절차, 이용자와 서비스 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"란 연세대학교 유학생들을 위한 커뮤니티 플랫폼으로, 정보 공유, 생활 지원, 의료 정보 등을 제공하는 모바일 애플리케이션을 말합니다.
2. "이용자"란 본 약관에 따라 서비스를 이용하는 회원 및 비회원을 말합니다.
3. "회원"이란 서비스에 가입하여 지속적으로 서비스를 이용할 수 있는 자를 말합니다.

제3조 (약관의 효력 및 변경)
1. 본 약관은 서비스를 이용하고자 하는 모든 이용자에게 그 효력이 발생합니다.
2. 서비스는 필요한 경우 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있습니다.
3. 약관이 변경되는 경우, 서비스는 변경사항을 시행일자 7일 전부터 공지합니다.

제4조 (회원가입)
1. 이용자는 서비스가 정한 가입 양식에 따라 회원정보를 기입한 후 본 약관에 동의한다는 의사표시를 함으로써 회원가입을 신청합니다.
2. 서비스는 다음 각 호에 해당하지 않는 한 회원가입을 승인합니다:
   - 가입신청자가 본 약관에 의하여 이전에 회원자격을 상실한 적이 있는 경우
   - 실명이 아니거나 타인의 명의를 이용한 경우
   - 허위의 정보를 기재하거나, 서비스가 제시하는 내용을 기재하지 않은 경우
3. 회원가입 시 학생증 사진을 제출해야 하며, 관리자의 승인 후 서비스 이용이 가능합니다.

제5조 (개인정보의 보호)
서비스는 관련 법령이 정하는 바에 따라 이용자의 개인정보를 보호하기 위해 노력합니다. 개인정보의 보호 및 이용에 대해서는 관련 법령 및 서비스의 개인정보처리방침이 적용됩니다.

제6조 (서비스의 제공 및 변경)
1. 서비스는 다음과 같은 업무를 수행합니다:
   - 커뮤니티 게시판 제공
   - 생활 정보 및 교통 정보 제공
   - 의료 정보 및 증상 카드 작성 지원
   - 아르바이트 정보 및 이력서 작성 지원
2. 서비스는 필요한 경우 제공하는 서비스의 내용을 변경할 수 있습니다.

제7조 (서비스의 중단)
1. 서비스는 컴퓨터 등 정보통신설비의 보수점검, 교체 및 고장, 통신의 두절 등의 사유가 발생한 경우에는 서비스의 제공을 일시적으로 중단할 수 있습니다.
2. 서비스는 제1항의 사유로 서비스의 제공이 일시적으로 중단됨으로 인하여 이용자 또는 제3자가 입은 손해에 대하여 배상합니다. 단, 서비스에 고의 또는 과실이 없는 경우에는 그러하지 아니합니다.

제8조 (이용자의 의무)
1. 이용자는 다음 행위를 하여서는 안 됩니다:
   - 신청 또는 변경 시 허위내용의 등록
   - 타인의 정보 도용
   - 서비스에 게시된 정보의 변경
   - 서비스가 정한 정보 이외의 정보(컴퓨터 프로그램 등) 등의 송신 또는 게시
   - 서비스 기타 제3자의 저작권 등 지적재산권에 대한 침해
   - 서비스 기타 제3자의 명예를 손상시키거나 업무를 방해하는 행위
   - 외설 또는 폭력적인 메시지, 화상, 음성, 기타 공서양속에 반하는 정보를 서비스에 공개 또는 게시하는 행위

제9조 (게시물의 관리)
1. 이용자가 작성한 게시물에 대한 권리는 이용자에게 있습니다.
2. 서비스는 다음 각 호에 해당하는 게시물이나 자료를 사전통지 없이 삭제하거나 이동 또는 등록 거부를 할 수 있습니다:
   - 다른 회원 또는 제3자에게 심한 모욕을 주거나 명예를 손상시키는 내용
   - 공공질서 및 미풍양속에 위반되는 내용
   - 범죄적 행위에 결부된다고 인정되는 내용
   - 제3자의 저작권 등 기타 권리를 침해하는 내용

제10조 (책임제한)
1. 서비스는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.
2. 서비스는 이용자의 귀책사유로 인한 서비스 이용의 장애에 대하여 책임을 지지 않습니다.
3. 서비스는 이용자가 서비스에 게재한 정보의 신뢰도, 정확성 등 내용에 관하여는 책임을 지지 않습니다.

제11조 (분쟁해결)
1. 서비스는 이용자가 제기하는 정당한 의견이나 불만을 반영하고 그 피해를 보상처리하기 위하여 피해보상처리기구를 설치·운영합니다.
2. 서비스와 이용자 간에 발생한 전자상거래 분쟁에 관한 소송은 대한민국 법령을 적용하며, 서비스의 주소지를 관할하는 법원을 전속 관할법원으로 합니다.

부칙
본 약관은 2024년 1월 1일부터 시행합니다.

연락처:
- 이메일: support@yonseibridge.com
- 주소: 강원도 원주시 연세대학교
''';

      case 'en':
        return '''
YONSEI BRIDGE Terms of Service

Article 1 (Purpose)
These Terms and Conditions aim to define the terms and procedures of use of all services provided by YONSEI BRIDGE (hereinafter referred to as "Service"), and the rights, obligations, and responsibilities between users and the Service.

Article 2 (Definitions)
1. "Service" refers to a mobile application that provides a community platform for international students at Yonsei University, offering information sharing, living support, medical information, etc.
2. "User" refers to members and non-members who use the Service in accordance with these Terms.
3. "Member" refers to a person who can continuously use the Service by registering with the Service.

Article 3 (Effectiveness and Amendment of Terms)
1. These Terms shall take effect for all users who wish to use the Service.
2. The Service may change these Terms to the extent that they do not violate relevant laws.
3. If the Terms are changed, the Service shall announce the changes from 7 days before the effective date.

Article 4 (Membership Registration)
1. Users apply for membership by filling in membership information according to the registration form determined by the Service and expressing their intention to agree to these Terms.
2. The Service shall approve membership registration unless it falls under any of the following:
   - If the applicant has previously lost membership qualifications under these Terms
   - If using a name that is not a real name or using another person's name
   - If false information is provided or the information requested by the Service is not provided
3. Student ID photo must be submitted during registration, and service access is granted after administrator approval.

Article 5 (Protection of Personal Information)
The Service strives to protect users' personal information as prescribed by relevant laws. The protection and use of personal information shall be governed by relevant laws and the Service's Privacy Policy.

Article 6 (Provision and Modification of Services)
1. The Service performs the following tasks:
   - Providing community bulletin boards
   - Providing living information and transportation information
   - Supporting medical information and symptom card creation
   - Supporting part-time job information and resume creation
2. The Service may change the content of the services provided if necessary.

Article 7 (Service Interruption)
1. The Service may temporarily suspend the provision of services in case of maintenance, replacement and failure of information and communication facilities such as computers, or disruption of communication.
2. The Service shall compensate for damages suffered by users or third parties due to temporary suspension of service provision for the reasons in Paragraph 1. However, this shall not apply if the Service has no intention or negligence.

Article 8 (User Obligations)
1. Users shall not engage in the following acts:
   - Registration of false information upon application or change
   - Theft of others' information
   - Alteration of information posted on the Service
   - Transmission or posting of information other than information determined by the Service (such as computer programs)
   - Infringement of intellectual property rights such as copyrights of the Service and other third parties
   - Acts that damage the reputation of the Service or other third parties or interfere with their business
   - Acts of disclosing or posting obscene or violent messages, images, voices, and other information contrary to public order and morals on the Service

Article 9 (Management of Posts)
1. The rights to posts created by users belong to the users.
2. The Service may delete, move, or refuse registration of posts or materials that fall under any of the following without prior notice:
   - Content that seriously insults or damages the reputation of other members or third parties
   - Content that violates public order and good morals
   - Content deemed to be associated with criminal activities
   - Content that infringes on copyrights or other rights of third parties

Article 10 (Limitation of Liability)
1. The Service shall be exempted from liability for service provision if it cannot provide services due to natural disasters or equivalent force majeure.
2. The Service shall not be liable for service usage障 caused by users' fault.
3. The Service shall not be liable for the reliability, accuracy, and other content of information posted by users on the Service.

Article 11 (Dispute Resolution)
1. The Service establishes and operates a damage compensation processing organization to reflect legitimate opinions or complaints raised by users and compensate for their damages.
2. Litigation concerning electronic commerce disputes between the Service and users shall apply Korean laws, and the court having jurisdiction over the Service's address shall be the exclusive jurisdictional court.

Addendum
These Terms shall be effective from January 1, 2024.

Contact:
- Email: support@yonseibridge.com
- Address: Yonsei University, Wonju, Gangwon-do, South Korea
''';

      case 'zh':
        return '''
YONSEI BRIDGE 使用条款

第1条 (目的)
本条款旨在规定YONSEI BRIDGE(以下简称"服务")提供的所有服务的使用条件和程序，以及用户与服务之间的权利、义务和责任事项。

第2条 (定义)
1. "服务"是指为延世大学留学生提供的社区平台移动应用程序，提供信息共享、生活支持、医疗信息等服务。
2. "用户"是指根据本条款使用服务的会员和非会员。
3. "会员"是指注册服务并可以持续使用服务的人。

第3条 (条款的效力和变更)
1. 本条款对所有希望使用服务的用户生效。
2. 服务可在不违反相关法律的范围内变更本条款。
3. 如条款变更，服务将从生效日期前7天起公告变更事项。

第4条 (会员注册)
1. 用户按照服务规定的注册表格填写会员信息，并表示同意本条款后申请会员注册。
2. 除以下情况外，服务应批准会员注册：
   - 申请人根据本条款曾失去会员资格
   - 使用非真实姓名或他人姓名
   - 提供虚假信息或未提供服务要求的信息
3. 注册时必须提交学生证照片，管理员批准后方可使用服务。

第5条 (个人信息保护)
服务根据相关法律规定努力保护用户的个人信息。个人信息的保护和使用应遵守相关法律和服务的隐私政策。

第6条 (服务的提供和变更)
1. 服务执行以下任务：
   - 提供社区公告板
   - 提供生活信息和交通信息
   - 支持医疗信息和症状卡创建
   - 支持兼职信息和简历创建
2. 服务可根据需要变更提供的服务内容。

第7条 (服务中断)
1. 如因计算机等信息通信设施的维护检查、更换和故障、通信中断等原因，服务可暂时中断服务提供。
2. 服务应对因第1款原因导致服务暂时中断而使用户或第三方遭受的损害进行赔偿。但是，如服务无故意或过失，则不在此限。

第8条 (用户义务)
1. 用户不得从事以下行为：
   - 申请或变更时登记虚假内容
   - 盗用他人信息
   - 变更服务上发布的信息
   - 传输或发布服务规定信息以外的信息(如计算机程序等)
   - 侵犯服务及其他第三方的著作权等知识产权
   - 损害服务及其他第三方名誉或妨碍其业务的行为
   - 在服务上公开或发布淫秽或暴力信息、图像、声音及其他违反公共秩序和善良风俗的信息

第9条 (帖子管理)
1. 用户创建的帖子的权利归用户所有。
2. 服务可以在不事先通知的情况下删除、移动或拒绝登记以下帖子或资料：
   - 严重侮辱或损害其他会员或第三方名誉的内容
   - 违反公共秩序和善良风俗的内容
   - 被认为与犯罪行为有关的内容
   - 侵犯第三方著作权等其他权利的内容

第10条 (责任限制)
1. 如因自然灾害或等同的不可抗力而无法提供服务，服务免除服务提供责任。
2. 服务对因用户过错导致的服务使用障碍不承担责任。
3. 服务对用户在服务上发布的信息的可靠性、准确性等内容不承担责任。

第11条 (争议解决)
1. 服务设立并运营损害赔偿处理机构，以反映用户提出的正当意见或投诉并补偿其损害。
2. 服务与用户之间发生的电子商务争议相关诉讼应适用韩国法律，以服务地址所在地法院为专属管辖法院。

附则
本条款自2024年1月1日起施行。

联系方式：
- 电子邮件：support@yonseibridge.com
- 地址：韩国江原道原州市延世大学
''';

      case 'ja':
        return '''
YONSEI BRIDGE 利用規約

第1条 (目的)
本規約は、YONSEI BRIDGE(以下「サービス」)が提供するすべてのサービスの利用条件および手続き、利用者とサービス間の権利、義務および責任事項を規定することを目的とします。

第2条 (定義)
1. 「サービス」とは、延世大学の留学生のためのコミュニティプラットフォームモバイルアプリケーションを指し、情報共有、生活支援、医療情報などを提供します。
2. 「利用者」とは、本規約に従ってサービスを利用する会員および非会員を指します。
3. 「会員」とは、サービスに登録し、継続的にサービスを利用できる者を指します。

第3条 (規約の効力および変更)
1. 本規約は、サービスを利用しようとするすべての利用者に対して効力を生じます。
2. サービスは、関連法令に違反しない範囲で本規約を変更することができます。
3. 規約が変更される場合、サービスは施行日の7日前から変更事項を公告します。

第4条 (会員登録)
1. 利用者は、サービスが定めた登録フォームに会員情報を記入し、本規約に同意する意思表示をすることで会員登録を申請します。
2. サービスは、以下の各号に該当しない限り会員登録を承認します：
   - 申請者が本規約により以前に会員資格を喪失したことがある場合
   - 実名でない、または他人の名義を利用した場合
   - 虚偽の情報を記載した、またはサービスが提示する内容を記載しなかった場合
3. 会員登録時に学生証の写真を提出する必要があり、管理者の承認後にサービス利用が可能になります。

第5条 (個人情報の保護)
サービスは、関連法令が定めるところにより、利用者の個人情報を保護するために努力します。個人情報の保護および利用については、関連法令およびサービスのプライバシーポリシーが適用されます。

第6条 (サービスの提供および変更)
1. サービスは以下の業務を遂行します：
   - コミュニティ掲示板の提供
   - 生活情報および交通情報の提供
   - 医療情報および症状カード作成の支援
   - アルバイト情報および履歴書作成の支援
2. サービスは、必要に応じて提供するサービスの内容を変更することができます。

第7条 (サービスの中断)
1. サービスは、コンピュータなどの情報通信設備の保守点検、交換および故障、通信の途絶などの事由が発生した場合、サービスの提供を一時的に中断することができます。
2. サービスは、第1項の事由によりサービスの提供が一時的に中断されたことにより利用者または第三者が被った損害について賠償します。ただし、サービスに故意または過失がない場合はこの限りではありません。

第8条 (利用者の義務)
1. 利用者は以下の行為をしてはなりません：
   - 申請または変更時に虚偽内容の登録
   - 他人の情報の盗用
   - サービスに掲示された情報の変更
   - サービスが定めた情報以外の情報(コンピュータプログラムなど)などの送信または掲示
   - サービスその他第三者の著作権などの知的財産権に対する侵害
   - サービスその他第三者の名誉を損なう、または業務を妨害する行為
   - 猥褻または暴力的なメッセージ、画像、音声、その他公序良俗に反する情報をサービスに公開または掲示する行為

第9条 (投稿の管理)
1. 利用者が作成した投稿に対する権利は利用者にあります。
2. サービスは、以下の各号に該当する投稿や資料を事前通知なしに削除、移動、または登録拒否することができます：
   - 他の会員または第三者にひどい侮辱を与える、または名誉を損なう内容
   - 公序良俗に違反する内容
   - 犯罪行為に関連すると認められる内容
   - 第三者の著作権などその他の権利を侵害する内容

第10条 (責任制限)
1. サービスは、天災地変またはこれに準ずる不可抗力によりサービスを提供できない場合、サービス提供に関する責任が免除されます。
2. サービスは、利用者の帰責事由によるサービス利用の障害について責任を負いません。
3. サービスは、利用者がサービスに掲載した情報の信頼度、正確性などの内容については責任を負いません。

第11条 (紛争解決)
1. サービスは、利用者が提起する正当な意見や不満を反映し、その被害を補償処理するために被害補償処理機構を設置・運営します。
2. サービスと利用者間で発生した電子商取引紛争に関する訴訟は、大韓民国の法令を適用し、サービスの住所地を管轄する裁判所を専属管轄裁判所とします。

附則
本規約は2024年1月1日から施行します。

連絡先：
- メール：support@yonseibridge.com
- 住所：大韓民国 江原道 原州市 延世大学
''';

      default:
        return _getTermsContent('ko');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.translate('terms_of_service')),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTermsContent(languageService.currentLanguage),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
