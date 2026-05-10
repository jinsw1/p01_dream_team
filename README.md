## 작업환경
- 실습용 VMware 사용도 가능
  GitHub CI/CD 적용 전 이므로 로컬 설치가 생각보다 복잡하여 VMware 사용도 괜찮음
  
  ** 단, github의 자원은 /home/user1/project01/ 하위에 위치 권장 **
  ** /home/user1/project01/dream_team **  

- local
  - WSL(Windows Subsystem for Linux)
    - Windows 안에서 Linux 환경 실행해주는 기능 (Ubuntu)
	- Local 환경에서 Terraform 실행은 가능하지만 Ansible 실행환경을 만들어주기 위함
	- WLS 및 Ubuntu 설치 후 ( Terrafom / Ansible / AWS CLI 및 Access-key 등록 )

	- WSL 및 ubuntu 설치방법
	  1. PowerShell 실행
	    > wsl --install  (설치중 묻는게 나온다면 n 입력)
	  2. 설치완료 후 재부팅
	  3. 설치확인 PowerShell 
	    > wsl --status
	  4. Ubuntu 실행
	    - 시작메뉴 > Ubuntu 또는 WSL 실행
	  5. 처음실행시 사용자이름 및 비밀번호 생성 (ex: user)
	  6. 접속시 user home 폴더에 위치
	    > pwd (위치확인)
	     /home/user
	  7. C드라이브 또는 D드라이브 경로이동 방법
	    > cd /mnt/c/
		> cd /mnt/d/

	  ** github의 자원은 /home/user/project01/ 하위에 위치 권장 **
	  ** 강의자료 참고하여 Ubuntu 용으로 (Terrafom / Ansible / AWS CLI 및 Access-key 등록) **

## 작업내용
2026.05.10
- Terraform 
  : bastion-ec2, was-ec2, db-ec2 생성 및 ALB 설정
  : ansible 실행에 필요한 ansible/inventories/dev/inventory.yml 생성
- Ansible
  : was-ec2 서버에 nginx 기본설치
- AWS 관리자 접속 후 생성된 로드밸런서의 (project01-alb 상세페이지) 접속 (DNS 이름) 생성된 A레코드 Url 입력시
  Nginx 기본페이지 연결되면 성공

******
  - Terraform = 인프라 도구
  - Ansible = 구성 도구	
  - Terraform 안에서 즉 직접 Ansible 실행하여 Apply 과정에 포함시킬경우 위험요소
    - Ansible이 서버 안을 바꿔도 Terraform은 추적 못 함.
      (처음부터 다시 해야 하는지 / Ansible만 다시 해야 하는지 / 일부만 수정되는지)

  - 작동 방식은 Terraform 으로 ansible에 필요한 (inventory.yml) ip 정보 등.. 실행환경 구성까지
  - 이후 ansible 실행

  - GitHub Actions 적용시
	Job 1: terraform apply
	Job 2: ansible-playbook
******

~ Todo List
  - S3 bucket 
  - DynamoDB lock table
  - bootstrap
  ....

## 실행순서
	-실습용 VMware 경우
	  ** 1. /home/user1/Project01/dream_team/terraform/env/dev 내에서
		  > terraform init
		  > terraform plan
		  > terraform apply --auto-approve

	  ** 2. /home/user1/Project01/dream_team/ansible/ 내에서
	      > ansible-playbook palybook/site.yml

	-로컬 WSL ubuntu 경우
	  ** 1. /home/user1/Project01/dream_team/terraform/env/dev 내에서
		  > terraform init
		  > terraform plan
		  > terraform apply --auto-approve

	  ** 2. /home/user1/Project01/dream_team/ansible/ 내에서
	      > ansible-playbook palybook/site.yml