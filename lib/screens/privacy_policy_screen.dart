import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  String _getPrivacyContent(String language) {
    switch (language) {
      case 'ko':
        return '''
YONSEI BRIDGE 개인정보처리방침

YONSEI BRIDGE(이하 "서비스")는 이용자의 개인정보를 중요시하며, 「개인정보 보호법」 등 관련 법령을 준수하고 있습니다. 서비스는 개인정보처리방침을 통하여 이용자가 제공하는 개인정보가 어떠한 용도와 방식으로 이용되고 있으며, 개인정보보호를 위해 어떠한 조치가 취해지고 있는지 알려드립니다.

제1조 (개인정보의 수집 및 이용 목적)
서비스는 다음의 목적을 위하여 개인정보를 처리합니다:
1. 회원가입 및 관리
   - 회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증
   - 회원자격 유지·관리, 서비스 부정이용 방지
2. 서비스 제공
   - 커뮤니티 게시판 이용, 게시물 작성 및 관리
   - 생활 정보, 교통 정보, 의료 정보 제공
   - 아르바이트 정보 및 이력서 작성 지원
3. 고충처리
   - 민원인의 신원 확인, 민원사항 확인, 사실조사를 위한 연락·통지
   - 처리결과 통보

제2조 (수집하는 개인정보의 항목)
서비스는 회원가입, 원활한 고객상담, 각종 서비스의 제공을 위해 최초 회원가입 당시 아래와 같은 개인정보를 수집하고 있습니다:
1. 필수항목
   - 이름, 학번(또는 ID), 비밀번호
   - 국적, 연락처
   - 학생증 사진 (회원가입 승인용)
2. 선택항목
   - 프로필 사진
3. 자동 수집 정보
   - IP 주소, 쿠키, 방문 일시
   - 서비스 이용 기록, 불량 이용 기록

제3조 (개인정보의 보유 및 이용기간)
1. 서비스는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.
2. 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:
   - 회원 가입 및 관리: 회원 탈퇴 시까지
   - 학생증 사진: 회원가입 승인 또는 거부 즉시 영구 삭제
   - 게시물 및 댓글: 회원 탈퇴 시 또는 게시물 삭제 시까지

제4조 (개인정보의 제3자 제공)
서비스는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다. 다만, 아래의 경우에는 예외로 합니다:
1. 이용자들이 사전에 동의한 경우
2. 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우

제5조 (개인정보의 파기)
1. 서비스는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.
2. 개인정보 파기의 절차 및 방법은 다음과 같습니다:
   - 파기절차: 이용자가 입력한 정보는 목적 달성 후 별도의 DB에 옮겨져 내부 방침 및 기타 관련 법령에 따라 일정기간 저장된 후 혹은 즉시 파기됩니다.
   - 파기방법: 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용합니다.
3. 특히 학생증 사진은 회원가입 승인 또는 거부 결정 즉시 서버에서 영구적으로 삭제되며, 어떠한 백업도 보관하지 않습니다.

제6조 (정보주체의 권리·의무 및 행사방법)
1. 이용자는 서비스에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:
   - 개인정보 열람요구
   - 오류 등이 있을 경우 정정 요구
   - 삭제요구
   - 처리정지 요구
2. 제1항에 따른 권리 행사는 서비스에 대해 서면, 전화, 전자우편 등을 통하여 하실 수 있으며 서비스는 이에 대해 지체없이 조치하겠습니다.

제7조 (개인정보 보호책임자)
서비스는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제를 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다:

개인정보 보호책임자
- 성명: YONSEI BRIDGE 운영팀
- 이메일: support@yonseibridge.com
- 전화번호: 문의사항은 이메일로 부탁드립니다

제8조 (개인정보의 안전성 확보조치)
서비스는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다:
1. 관리적 조치: 내부관리계획 수립·시행, 정기적 직원 교육
2. 기술적 조치: 개인정보처리시스템 등의 접근권한 관리, 접근통제시스템 설치, 개인정보의 암호화
3. 물리적 조치: 전산실, 자료보관실 등의 접근통제

제9조 (개인정보처리방침의 변경)
이 개인정보처리방침은 시행일로부터 적용되며, 법령 및 방침에 따른 변경내용의 추가, 삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할 것입니다.

제10조 (권익침해 구제방법)
이용자는 개인정보침해로 인한 구제를 받기 위하여 개인정보분쟁조정위원회, 한국인터넷진흥원 개인정보침해신고센터 등에 분쟁해결이나 상담 등을 신청할 수 있습니다.
- 개인정보분쟁조정위원회: (국번없이) 1833-6972 (www.kopico.go.kr)
- 개인정보침해신고센터: (국번없이) 118 (privacy.kisa.or.kr)

부칙
본 방침은 2024년 1월 1일부터 시행됩니다.
''';

      case 'en':
        return '''
YONSEI BRIDGE Privacy Policy

YONSEI BRIDGE (hereinafter "Service") values users' personal information and complies with relevant laws such as the "Personal Information Protection Act." Through this Privacy Policy, we inform you of the purpose and method of using the personal information you provide, and what measures are being taken to protect personal information.

Article 1 (Purpose of Collection and Use of Personal Information)
The Service processes personal information for the following purposes:
1. Membership registration and management
   - Confirmation of membership intention, identification and authentication for member services
   - Maintenance and management of membership qualifications, prevention of fraudulent use of services
2. Service provision
   - Use of community bulletin boards, creation and management of posts
   - Provision of living information, transportation information, medical information
   - Support for part-time job information and resume creation
3. Grievance handling
   - Identification of complainants, confirmation of complaints, contact and notification for fact-finding
   - Notification of processing results

Article 2 (Items of Personal Information Collected)
The Service collects the following personal information at the time of initial membership registration for membership, smooth customer consultation, and provision of various services:
1. Required items
   - Name, student number (or ID), password
   - Nationality, contact information
   - Student ID photo (for membership approval)
2. Optional items
   - Profile photo
3. Automatically collected information
   - IP address, cookies, visit date and time
   - Service usage records, fraudulent use records

Article 3 (Retention and Use Period of Personal Information)
1. The Service processes and retains personal information within the retention and use period of personal information under laws or the retention and use period agreed upon when collecting personal information from data subjects.
2. The processing and retention period of each personal information is as follows:
   - Membership registration and management: Until membership withdrawal
   - Student ID photo: Permanently deleted immediately upon membership approval or rejection
   - Posts and comments: Until membership withdrawal or post deletion

Article 4 (Provision of Personal Information to Third Parties)
In principle, the Service does not provide users' personal information to third parties. However, exceptions are made in the following cases:
1. When users have consented in advance
2. When required by laws or when requested by investigative agencies in accordance with procedures and methods prescribed by laws for investigation purposes

Article 5 (Destruction of Personal Information)
1. The Service shall promptly destroy personal information when it becomes unnecessary, such as when the retention period of personal information has elapsed or the purpose of processing has been achieved.
2. The procedures and methods of personal information destruction are as follows:
   - Destruction procedure: Information entered by users is transferred to a separate DB after the purpose is achieved and stored for a certain period according to internal policies and other relevant laws, or destroyed immediately.
   - Destruction method: Information in electronic file format uses technical methods that cannot reproduce records.
3. In particular, student ID photos are permanently deleted from the server immediately upon membership approval or rejection, and no backups are retained.

Article 6 (Rights and Obligations of Data Subjects and Exercise Methods)
1. Users may exercise the following personal information protection-related rights against the Service at any time:
   - Request to view personal information
   - Request to correct errors, etc.
   - Request to delete
   - Request to stop processing
2. The exercise of rights under Paragraph 1 may be made to the Service in writing, by phone, email, etc., and the Service will take action without delay.

Article 7 (Person Responsible for Personal Information Protection)
The Service designates the following person responsible for personal information protection to oversee personal information processing-related tasks and to handle complaints and remedy damages related to personal information processing:

Person Responsible for Personal Information Protection
- Name: YONSEI BRIDGE Operations Team
- Email: support@yonseibridge.com
- Phone: Please contact by email for inquiries

Article 8 (Measures to Ensure Safety of Personal Information)
The Service takes the following measures to ensure the safety of personal information:
1. Administrative measures: Establishment and implementation of internal management plans, regular employee training
2. Technical measures: Management of access rights to personal information processing systems, installation of access control systems, encryption of personal information
3. Physical measures: Access control to computer rooms, data storage rooms, etc.

Article 9 (Changes to Privacy Policy)
This Privacy Policy applies from the effective date, and if there are additions, deletions, and corrections to changes according to laws and policies, notice will be given through announcements from 7 days before the implementation of changes.

Article 10 (Remedy for Rights Infringement)
Users may apply for dispute resolution or consultation to the Personal Information Dispute Mediation Committee, Korea Internet & Security Agency Personal Information Infringement Report Center, etc. to receive relief from personal information infringement.
- Personal Information Dispute Mediation Committee: 1833-6972 (www.kopico.go.kr)
- Personal Information Infringement Report Center: 118 (privacy.kisa.or.kr)

Addendum
This policy is effective from January 1, 2024.
''';

      case 'zh':
        return '''
YONSEI BRIDGE 隐私政策

YONSEI BRIDGE(以下简称"服务")重视用户的个人信息，并遵守《个人信息保护法》等相关法律。通过本隐私政策，我们告知您所提供的个人信息用于何种目的和方式，以及为保护个人信息采取了哪些措施。

第1条 (个人信息的收集和使用目的)
服务出于以下目的处理个人信息：
1. 会员注册和管理
   - 确认会员意向，为会员服务提供身份识别和认证
   - 维护和管理会员资格，防止服务的欺诈性使用
2. 服务提供
   - 使用社区公告板，创建和管理帖子
   - 提供生活信息、交通信息、医疗信息
   - 支持兼职信息和简历创建
3. 投诉处理
   - 确认投诉人身份，确认投诉事项，为调查联系和通知
   - 通知处理结果

第2条 (收集的个人信息项目)
服务在初次会员注册时为会员注册、顺畅的客户咨询和提供各种服务收集以下个人信息：
1. 必填项目
   - 姓名、学号(或ID)、密码
   - 国籍、联系方式
   - 学生证照片(用于会员批准)
2. 可选项目
   - 个人资料照片
3. 自动收集信息
   - IP地址、cookies、访问日期和时间
   - 服务使用记录、欺诈使用记录

第3条 (个人信息的保留和使用期限)
1. 服务在法律规定的个人信息保留和使用期限内或从数据主体收集个人信息时同意的个人信息保留和使用期限内处理和保留个人信息。
2. 各个人信息的处理和保留期限如下：
   - 会员注册和管理：直到会员退出
   - 学生证照片：会员批准或拒绝后立即永久删除
   - 帖子和评论：直到会员退出或帖子删除

第4条 (向第三方提供个人信息)
原则上，服务不向第三方提供用户的个人信息。但是，以下情况除外：
1. 用户事先同意
2. 根据法律要求或根据法律规定的程序和方法由调查机关要求进行调查

第5条 (个人信息的销毁)
1. 当个人信息变得不必要时，例如个人信息保留期限已过或处理目的已达成，服务应立即销毁该个人信息。
2. 个人信息销毁的程序和方法如下：
   - 销毁程序：用户输入的信息在目的达成后转移到单独的数据库，并根据内部政策和其他相关法律存储一定期限后或立即销毁。
   - 销毁方法：电子文件格式的信息使用无法重现记录的技术方法。
3. 特别是，学生证照片在会员批准或拒绝后立即从服务器永久删除，不保留任何备份。

第6条 (数据主体的权利、义务和行使方法)
1. 用户可以随时针对服务行使以下与个人信息保护相关的权利：
   - 要求查看个人信息
   - 要求更正错误等
   - 要求删除
   - 要求停止处理
2. 根据第1款的权利行使可以通过书面、电话、电子邮件等方式向服务提出，服务将立即采取行动。

第7条 (个人信息保护负责人)
服务指定以下个人信息保护负责人来监督与个人信息处理相关的任务，并处理与个人信息处理相关的投诉和损害赔偿：

个人信息保护负责人
- 姓名：YONSEI BRIDGE 运营团队
- 电子邮件：support@yonseibridge.com
- 电话：咨询请通过电子邮件联系

第8条 (确保个人信息安全的措施)
服务采取以下措施以确保个人信息的安全：
1. 管理措施：制定和实施内部管理计划，定期员工培训
2. 技术措施：管理个人信息处理系统的访问权限，安装访问控制系统，加密个人信息
3. 物理措施：对计算机室、数据存储室等进行访问控制

第9条 (隐私政策的变更)
本隐私政策自生效日期起适用，如果根据法律和政策有增加、删除和更正变更内容，将从变更实施前7天通过公告发出通知。

第10条 (权利侵犯的补救)
用户可以向个人信息争议调解委员会、韩国互联网与安全局个人信息侵犯举报中心等申请争议解决或咨询，以获得个人信息侵犯的补救。
- 个人信息争议调解委员会：1833-6972 (www.kopico.go.kr)
- 个人信息侵犯举报中心：118 (privacy.kisa.or.kr)

附则
本政策自2024年1月1日起生效。
''';

      case 'ja':
        return '''
YONSEI BRIDGE プライバシーポリシー

YONSEI BRIDGE(以下「サービス」)は、利用者の個人情報を重視し、「個人情報保護法」などの関連法令を遵守しています。サービスは、プライバシーポリシーを通じて、利用者が提供する個人情報がどのような目的と方式で利用されているか、個人情報保護のためにどのような措置が取られているかをお知らせします。

第1条 (個人情報の収集及び利用目的)
サービスは次の目的のために個人情報を処理します：
1. 会員登録及び管理
   - 会員登録意思の確認、会員制サービス提供に伴う本人識別・認証
   - 会員資格維持・管理、サービスの不正利用防止
2. サービス提供
   - コミュニティ掲示板の利用、投稿の作成及び管理
   - 生活情報、交通情報、医療情報の提供
   - アルバイト情報及び履歴書作成の支援
3. 苦情処理
   - 苦情申立人の身元確認、苦情事項の確認、事実調査のための連絡・通知
   - 処理結果の通知

第2条 (収集する個人情報の項目)
サービスは、会員登録、円滑な顧客相談、各種サービスの提供のために、初回会員登録時に以下の個人情報を収集しています：
1. 必須項目
   - 氏名、学籍番号(またはID)、パスワード
   - 国籍、連絡先
   - 学生証の写真(会員登録承認用)
2. 選択項目
   - プロフィール写真
3. 自動収集情報
   - IPアドレス、クッキー、訪問日時
   - サービス利用記録、不正利用記録

第3条 (個人情報の保有及び利用期間)
1. サービスは、法令に基づく個人情報保有・利用期間または情報主体から個人情報を収集する際に同意を得た個人情報保有・利用期間内で個人情報を処理・保有します。
2. 各個人情報の処理及び保有期間は以下の通りです：
   - 会員登録及び管理：会員退会まで
   - 学生証の写真：会員登録承認または拒否後直ちに永久削除
   - 投稿及びコメント：会員退会時または投稿削除時まで

第4条 (個人情報の第三者提供)
サービスは原則として利用者の個人情報を第三者に提供しません。ただし、以下の場合は例外とします：
1. 利用者が事前に同意した場合
2. 法令の規定により、または捜査目的で法令に定められた手続きと方法に従って捜査機関の要求がある場合

第5条 (個人情報の破棄)
1. サービスは、個人情報保有期間の経過、処理目的達成など個人情報が不要になった場合、遅滞なく当該個人情報を破棄します。
2. 個人情報破棄の手続き及び方法は以下の通りです：
   - 破棄手続き：利用者が入力した情報は目的達成後、別途のデータベースに移され、内部方針及びその他関連法令に従って一定期間保存された後、または直ちに破棄されます。
   - 破棄方法：電子ファイル形式の情報は、記録を再生できない技術的方法を使用します。
3. 特に学生証の写真は、会員登録承認または拒否決定後直ちにサーバーから永久的に削除され、いかなるバックアップも保管しません。

第6条 (情報主体の権利・義務及び行使方法)
1. 利用者は、サービスに対していつでも次の各号の個人情報保護関連権利を行使できます：
   - 個人情報閲覧要求
   - 誤り等がある場合の訂正要求
   - 削除要求
   - 処理停止要求
2. 第1項に基づく権利行使は、サービスに対して書面、電話、電子メールなどを通じて行うことができ、サービスはこれに対して遅滞なく措置します。

第7条 (個人情報保護責任者)
サービスは、個人情報処理に関する業務を総括して責任を負い、個人情報処理に関連する情報主体の苦情処理及び被害救済のために、以下の通り個人情報保護責任者を指定しています：

個人情報保護責任者
- 氏名：YONSEI BRIDGE 運営チーム
- メール：support@yonseibridge.com
- 電話番号：お問い合わせはメールでお願いします

第8条 (個人情報の安全性確保措置)
サービスは、個人情報の安全性確保のために次のような措置を取っています：
1. 管理的措置：内部管理計画の策定・施行、定期的な職員教育
2. 技術的措置：個人情報処理システムなどのアクセス権限管理、アクセス制御システムの設置、個人情報の暗号化
3. 物理的措置：コンピュータ室、資料保管室などのアクセス制御

第9条 (プライバシーポリシーの変更)
このプライバシーポリシーは施行日から適用され、法令及び方針に基づく変更内容の追加、削除及び訂正がある場合、変更事項の施行の7日前からお知らせを通じて告知します。

第10条 (権益侵害救済方法)
利用者は、個人情報侵害による救済を受けるために、個人情報紛争調整委員会、韓国インターネット振興院個人情報侵害申告センターなどに紛争解決や相談などを申請できます。
- 個人情報紛争調整委員会：1833-6972 (www.kopico.go.kr)
- 個人情報侵害申告センター：118 (privacy.kisa.or.kr)

附則
本方針は2024年1月1日から施行します。
''';

      default:
        return _getPrivacyContent('ko');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.translate('privacy_policy')),
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
                _getPrivacyContent(languageService.currentLanguage),
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
