# Slash Rush - Character Select 화면 프로토타입 구현 지시문

Godot 프로젝트 Slash Rush에 Character Select 화면을 추가한다.

현재 MainMenu에 Character 버튼이 있지만, 연결될 Character Select 씬은 아직 없다.  
프로토타입 단계이므로 실제 캐릭터 선택, 해금 조건, 저장 기능은 구현하지 않는다.

목표는 “캐릭터 선택 화면처럼 보이는 UI”를 만드는 것이다.  
현재 기본 캐릭터는 player1.png이고, 나머지 캐릭터들은 잠긴 상태로 보여준다.

---

## 1. 에셋 위치

캐릭터 일러스트는 아래 폴더에 있다.

- res://assets/characters/player1.png
- res://assets/characters/player2.png
- res://assets/characters/player3.png
- res://assets/characters/player4.png
- res://assets/characters/player5.png

주의:
- 실제 파일명이 player2.png, player3.png 형식인지 먼저 확인한다.
- 파일명이 다르면 실제 파일명에 맞춰 수정한다.
- player1.png가 현재 기본 선택 캐릭터다.

---

## 2. 새 씬 생성

새 Character Select 씬을 만든다.

추천 경로:

- res://scenes/ui/CharacterSelect.tscn

프로젝트의 기존 UI 씬 경로 규칙이 다르면 기존 구조에 맞춰 생성한다.

루트 노드는 Control을 사용한다.

---

## 3. 화면 구성

모바일 가로모드 기준으로 구성한다.

상단:
- Back 버튼
- CHARACTER SELECT 타이틀

중앙:
- 1줄 가로 스크롤 캐릭터 카드 목록

카드 구성:
- player1 카드
- player2 카드
- player3 카드
- player4 카드
- player5 카드
- Coming Soon 빈 카드

하단:
- 안내 메시지 라벨

화면 개념:

← BACK        CHARACTER SELECT

[ player1 ] [ player2 ] [ player3 ] [ player4 ] [ player5 ] [ Coming Soon ]
 SELECTED     LOCKED      LOCKED      LOCKED      LOCKED        SOON

---

## 4. 가로 스크롤 UI

ScrollContainer + HBoxContainer를 사용한다.

요구사항:
- 캐릭터 카드는 1줄로 나열한다.
- 가로 스크롤이 가능해야 한다.
- 세로 스크롤은 필요 없다.
- 카드가 화면 밖으로 넘어가면 좌우로 스크롤 가능해야 한다.
- 카드 간 간격을 충분히 둔다.
- 화면 오른쪽 끝에 다음 카드가 살짝 보이게 하면 스크롤 가능하다는 느낌을 줄 수 있다.

추천 노드 구조:

CharacterSelect (Control)
- Background
- Header
  - BackButton
  - TitleLabel
- CharacterScrollContainer
  - CharacterHBox
    - CharacterCard_player1
    - CharacterCard_player2
    - CharacterCard_player3
    - CharacterCard_player4
    - CharacterCard_player5
    - CharacterCard_ComingSoon
- MessageLabel

---

## 5. 카드 크기와 비율

캐릭터 이미지는 세로형 인물 일러스트다.

원본 비율은 대략 1086x1448이므로 카드도 세로형 비율로 만든다.

추천 카드 크기:
- width: 180~220
- height: 320~380

프로젝트 해상도와 기존 MainMenu UI 크기에 맞춰 자연스럽게 조정한다.

중요:
- 이미지를 찌그러뜨리지 않는다.
- TextureRect는 비율 유지 설정을 사용한다.
- 전신이 너무 작아져도 괜찮다.
- 프로토타입에서는 캐릭터 감상보다 “캐릭터 목록이 있고 잠겨 있다”는 정보 전달이 더 중요하다.

---

## 6. player1 카드 상태

player1은 현재 선택된 기본 캐릭터다.

표시:
- player1.png 표시
- 밝게 표시
- 선택된 카드임을 알 수 있도록 테두리 강조
- StatusLabel에 SELECTED 표시
- 가능하면 작은 체크 표시도 추가

동작:
- 클릭 가능해도 된다.
- 클릭해도 실제 선택 변경은 하지 않는다.
- 클릭 시 MessageLabel에 “Already selected” 표시

주의:
- 기존 게임 시작 시 사용하는 기본 캐릭터 로직은 변경하지 않는다.
- player1은 항상 선택된 상태로 고정한다.

---

## 7. player2~player5 카드 상태

player2~player5는 모두 잠긴 상태다.

표시:
- 각 캐릭터 이미지는 보여준다.
- 이미지 위에 반투명 검은 오버레이를 얹는다.
- 중앙에 LOCKED 텍스트 또는 자물쇠 표시를 넣는다.
- StatusLabel에는 LOCKED 표시
- 선택된 카드처럼 보이면 안 된다.

동작:
- 클릭해도 선택되지 않아야 한다.
- 클릭 시 MessageLabel에 “Coming soon” 표시

주의:
- 해금 조건은 만들지 않는다.
- 재화, 업적, 레벨 조건, 스킨 구매 기능도 만들지 않는다.
- 저장 기능도 만들지 않는다.

---

## 8. 마지막 Coming Soon 카드

마지막 카드는 실제 캐릭터 이미지가 없는 빈 카드다.

표시:
- 흐린 카드 배경
- 중앙에 ? 또는 + 표시
- StatusLabel에 COMING SOON 표시
- 캐릭터 추가 예정이라는 느낌이 나야 한다.

동작:
- 클릭 시 MessageLabel에 “Coming soon” 표시

---

## 9. 캐릭터 데이터 구조

CharacterSelect.gd에서 캐릭터 정보를 배열로 관리한다.

예시 구조:

var characters := [
    {
        "id": "player1",
        "name": "Player 1",
        "image": "res://assets/characters/player1.png",
        "unlocked": true,
        "selected": true
    },
    {
        "id": "player2",
        "name": "Player 2",
        "image": "res://assets/characters/player2.png",
        "unlocked": false,
        "selected": false
    },
    {
        "id": "player3",
        "name": "Player 3",
        "image": "res://assets/characters/player3.png",
        "unlocked": false,
        "selected": false
    },
    {
        "id": "player4",
        "name": "Player 4",
        "image": "res://assets/characters/player4.png",
        "unlocked": false,
        "selected": false
    },
    {
        "id": "player5",
        "name": "Player 5",
        "image": "res://assets/characters/player5.png",
        "unlocked": false,
        "selected": false
    }
]

이 데이터는 현재 UI 표시용이다.  
실제 선택 저장이나 해금 시스템으로 연결하지 않는다.

---

## 10. MainMenu 연결

MainMenu의 Character 버튼을 눌렀을 때 CharacterSelect.tscn으로 이동하게 한다.

예시:

func _on_character_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")

단, 실제 MainMenu 스크립트와 씬 구조를 먼저 확인하고 기존 방식에 맞춰 연결한다.

주의:
- 기존 Start 버튼, How To 버튼, 게임 시작 기능을 깨뜨리지 않는다.
- Character 버튼 연결만 추가한다.

---

## 11. Back 버튼

CharacterSelect 화면의 Back 버튼을 누르면 MainMenu로 돌아가게 한다.

예시:

func _on_back_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

MainMenu 씬 경로가 다르면 실제 경로에 맞춰 수정한다.

---

## 12. MessageLabel

화면 하단 또는 우측 하단에 안내 메시지 라벨을 둔다.

초기 문구:

More characters will be available in future versions.

player1 클릭 시:

Already selected

잠긴 캐릭터 클릭 시:

Coming soon

Coming Soon 카드 클릭 시:

Coming soon

가능하면 메시지는 1~2초 뒤 초기 문구로 돌아가게 한다.  
구현이 번거로우면 메시지만 바뀌어도 된다.

---

## 13. 스타일 방향

Slash Rush는 모바일 가로모드 하이퍼 캐주얼 액션 러너 프로토타입이다.

UI는 너무 복잡하게 만들지 않는다.

스타일 요구:
- 어두운 반투명 배경
- 카드형 UI
- 선택된 카드 강조 테두리
- 잠긴 카드에는 반투명 검은 오버레이
- LOCKED 텍스트는 명확하게
- Coming Soon 카드는 빈 카드처럼 보이되 허전하지 않게
- 전체적으로 MainMenu와 어울리게 구성

---

## 14. 구현 시 주의사항

반드시 지킬 것:

1. 기존 MainMenu 기능을 깨뜨리지 말 것.
2. 기존 게임 시작 시 사용하는 기본 캐릭터 로직을 변경하지 말 것.
3. 실제 캐릭터 선택 저장 기능은 만들지 말 것.
4. player1만 SELECTED 상태로 고정할 것.
5. player2~player5는 LOCKED 상태로 고정할 것.
6. player2~player5는 클릭해도 선택되지 않게 할 것.
7. 해금 조건, 재화, 업적, 스킨 구매 기능은 만들지 말 것.
8. 가로 스크롤 UI가 실제로 동작해야 한다.
9. 캐릭터 이미지 비율이 깨지지 않게 한다.
10. 모바일 가로 화면에서 UI가 너무 작거나 찌그러지지 않게 한다.

---

## 15. 완료 기준

작업 완료 후 다음이 가능해야 한다.

- MainMenu에서 Character 버튼 클릭
- CharacterSelect 화면 진입
- player1은 SELECTED 상태로 표시
- player2~player5는 LOCKED 상태로 표시
- 마지막에 Coming Soon 빈 카드 표시
- 카드들은 1줄 가로 스크롤로 배치
- player1 클릭 시 Already selected 메시지 표시
- 잠긴 카드 클릭 시 Coming soon 메시지 표시
- Coming Soon 카드 클릭 시 Coming soon 메시지 표시
- Back 버튼으로 MainMenu 복귀
- 기존 게임 시작/플레이 기능은 영향 없음

---

## 16. 작업 완료 후 보고할 것

구현 후 아래 내용을 간단히 보고해줘.

1. 생성한 파일 목록
2. 수정한 파일 목록
3. MainMenu Character 버튼 연결 방식
4. CharacterSelect 화면 노드 구조 요약
5. 테스트 결과
6. 아직 남은 문제 또는 확인 필요한 부분