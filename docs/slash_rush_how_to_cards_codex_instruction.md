# Slash Rush - HOW TO 카드형 가이드 화면 구현 지시문

## 목적

`Mainmenu` 화면에서 `HOW TO` 버튼을 누르면, 게임 방법을 카드형 UI로 보여주는 별도 화면을 추가한다.

이번 구현의 목표는 **최대한 적은 구현 난이도와 빠른 작업 속도**이다.  
실제 플레이 가능한 튜토리얼이 아니라, **정적 카드형 설명 화면**을 먼저 완성한다.

중요한 점은 현재 게임에 이미 존재하는 실제 몬스터/아이템 변수명 또는 타입명을 기준으로 설명 카드가 구성되어야 한다는 것이다.

---

## 구현 대상

Godot 프로젝트에서 다음 기능을 구현한다.

```text
Mainmenu
  └─ HOW TO 버튼 클릭
        └─ HowTo 화면으로 이동
              ├─ 카드형 게임 가이드 표시
              ├─ Back 버튼으로 Mainmenu 복귀
              └─ Start 버튼이 있으면 기존 게임 시작 흐름으로 연결
```

---

## 실제 게임 오브젝트 매핑

아래 명칭은 반드시 실제 게임 내부 변수명/타입명 기준으로 사용한다.

| 설명 | 실제 변수명 / 타입명 |
|---|---|
| 한 대 맞으면 죽는 몬스터 | `enemy_basic`, `bomb` |
| 두 대 맞으면 죽는 몬스터 | `enemy_fast` |
| 롱탭 hold로 죽는 몬스터 | `enemy_armor` |
| 코인 | `coin` |
| Fever 아이템 | `fever_orb` |
| Heal 아이템 | `heal` |

주의사항:

- 카드에 표시되는 사용자용 문구는 자연스럽게 작성한다.
- 내부 데이터 매핑, 아이콘 선택, 리소스 참조 등은 위 변수명을 기준으로 구성한다.
- `bomb`은 한 대 맞으면 죽는 대상 그룹에 포함하되, 실제 게임 규칙상 폭탄이 피해야 하는 대상이면 문구를 조정해야 한다.
  - 현재 요청 기준에서는 `enemy_basic`, `bomb` 모두 “한 대 처리 대상” 카드에 포함한다.
  - 단, 기존 코드에서 `bomb`이 피해야 하는 장애물이라면 카드 문구는 “한 번의 입력으로 반응하는 위험 오브젝트”처럼 안전하게 수정한다.

---

## 1차 구현 방향

이번 구현에서는 아래 범위까지만 한다.

### 포함할 것

- HOW TO 화면 Scene 추가
- Mainmenu의 HOW TO 버튼 연결
- 카드형 UI 배치
- 카드 5개 구성
- Back 버튼
- 가능하면 Start 버튼
- 모바일 가로모드 기준으로 보기 좋은 레이아웃
- 기존 에셋이 있으면 재사용
- 에셋이 없으면 임시 Label / ColorRect / TextureRect placeholder 사용

### 포함하지 말 것

- 실제 조작 튜토리얼
- 미니 게임 시뮬레이션
- 복잡한 애니메이션
- 신규 몬스터 로직
- 신규 전투 로직
- 신규 아이템 효과 로직
- 지나치게 복잡한 페이지 전환 연출

목표는 “처음 보는 사람이 10초 안에 조작 규칙을 이해하는 화면”이다.

---

## 추천 Scene 구조

가능하면 아래 구조로 구현한다.

```text
HowToScreen.tscn
- Control
  - Background / ColorRect
  - SafeArea / MarginContainer
    - VBoxContainer
      - Header
        - Title Label: "HOW TO PLAY"
      - ScrollContainer
        - HBoxContainer
          - HowToCard 1
          - HowToCard 2
          - HowToCard 3
          - HowToCard 4
          - HowToCard 5
      - Footer
        - Back Button
        - Start Button
```

카드 컴포넌트는 가능하면 재사용 가능하게 만든다.

```text
HowToCard.tscn 또는 코드 생성 카드
- PanelContainer
  - MarginContainer
    - VBoxContainer
      - Icon Area
        - TextureRect 또는 Label
      - Title Label
      - Description Label
      - Optional Small Tag Label
```

단, 현재 프로젝트 구조상 별도 `HowToCard.tscn`을 만드는 것이 번거롭다면, `HowToScreen.gd` 내부에서 카드 UI를 코드로 생성해도 된다.  
이번 작업의 우선순위는 구조적 완성보다 빠른 구현이다.

---

## 카드 구성

총 5개 카드로 구성한다.

---

### Card 1. TAP

대상:

- `enemy_basic`
- `bomb`

사용자 표시 제목:

```text
TAP
```

설명 문구:

```text
기본 몬스터는 한 번 탭해서 제거하세요.
위험 오브젝트도 타이밍에 맞춰 빠르게 반응해야 합니다.
```

표시 요소:

```text
enemy_basic / bomb
```

구현 참고:

- 기존 `enemy_basic` 또는 `bomb` sprite/resource가 있으면 카드 안에 작게 표시한다.
- 둘 다 표시하기 어렵다면 `enemy_basic`만 대표로 보여줘도 된다.
- sprite가 없다면 `⚔ TAP` 또는 단순 도형 placeholder로 처리한다.

---

### Card 2. TAP TAP

대상:

- `enemy_fast`

사용자 표시 제목:

```text
TAP TAP
```

설명 문구:

```text
빠른 몬스터는 두 번 공격해야 제거됩니다.
연속 입력 타이밍을 놓치지 마세요.
```

표시 요소:

```text
enemy_fast
```

구현 참고:

- 카드 안에 `TAP TAP` 텍스트를 크게 보여준다.
- 가능하면 몬스터 아이콘 아래에 작은 `x2` 표시를 붙인다.

---

### Card 3. HOLD

대상:

- `enemy_armor`

사용자 표시 제목:

```text
HOLD
```

설명 문구:

```text
갑옷 몬스터는 길게 눌러 처리하세요.
게이지가 차는 느낌으로 Hold 타이밍을 익히면 됩니다.
```

표시 요소:

```text
enemy_armor
```

구현 참고:

- 카드 안에 정적 게이지를 하나 넣는다.
- 예시:

```text
[ HOLD █████ ]
```

- 애니메이션은 1차 구현에서 필수 아님.
- 시간이 남으면 Tween으로 게이지가 천천히 차는 반복 효과를 넣어도 된다.

---

### Card 4. ITEMS

대상:

- `coin`
- `fever_orb`
- `heal`

사용자 표시 제목:

```text
ITEMS
```

설명 문구:

```text
Coin은 점수를 올립니다.
Fever Orb는 피버 게이지를 채웁니다.
Heal은 체력을 회복합니다.
```

표시 요소:

```text
coin / fever_orb / heal
```

구현 참고:

- 카드 하나 안에 아이템 3개를 작게 나열한다.
- 실제 아이콘이 있으면 TextureRect 3개로 표시한다.
- 없으면 아래처럼 Label로 처리한다.

```text
🪙 Coin
🔥 Fever
❤ Heal
```

- 이모지가 게임 분위기와 맞지 않으면 단순 텍스트로 대체한다.

---

### Card 5. COMBO & FEVER

대상:

- Combo 시스템
- Fever 효과

사용자 표시 제목:

```text
COMBO & FEVER
```

설명 문구:

```text
연속으로 성공하면 콤보가 증가합니다.
실패하거나 피격되면 콤보가 초기화됩니다.
Fever 중에는 빠른 연속 공격이 발동하고 콤보가 더 안정적으로 유지됩니다.
```

구현 참고:

- 실제 콤보 로직을 수정하지 않는다.
- HOW TO 화면에서는 설명만 한다.
- `COMBO x12` 같은 예시 텍스트를 크게 보여주면 이해가 쉽다.
- Fever 효과는 `FEVER! TAP TAP TAP!` 같은 텍스트로 시각화한다.

---

## UI 레이아웃 기준

모바일 가로모드 기준으로 보기 좋게 만든다.

권장 기준:

```text
화면 방향: Landscape
카드 표시: 한 화면에 2~3장 정도 보이게
카드 이동: ScrollContainer 가로 스크롤
카드 비율: 세로로 길지 않게
문구: 짧게
폰트 크기: 모바일에서 읽기 쉽게
```

예시 배치:

```text
┌──────────────────────────────────────────────┐
│                 HOW TO PLAY                  │
│                                              │
│  [ TAP ]   [ TAP TAP ]   [ HOLD ]   [ ITEMS ]│
│                                              │
│        [ BACK ]                  [ START ]   │
└──────────────────────────────────────────────┘
```

카드가 화면 밖으로 넘어가면 `ScrollContainer`로 자연스럽게 좌우 스크롤되게 한다.

---

## Mainmenu 연결 요구사항

기존 Mainmenu에 `HOW TO` 버튼이 이미 있다면 해당 버튼의 pressed 이벤트를 연결한다.

예시 흐름:

```gdscript
func _on_how_to_button_pressed():
    get_tree().change_scene_to_file("res://path/to/HowToScreen.tscn")
```

정확한 경로는 현재 프로젝트 구조에 맞춘다.

만약 Mainmenu에 HOW TO 버튼이 없다면:

- 기존 버튼 스타일과 비슷하게 `HOW TO` 버튼을 추가한다.
- 메인 메뉴에서 너무 튀지 않게 배치한다.
- `START`, `HOW TO`, `QUIT` 순서가 자연스럽다.
- 모바일 게임이라면 `QUIT`은 없어도 된다.

---

## Back / Start 버튼 동작

### Back 버튼

HOW TO 화면에서 Mainmenu로 돌아간다.

```gdscript
func _on_back_pressed():
    get_tree().change_scene_to_file("res://path/to/Mainmenu.tscn")
```

### Start 버튼

Start 버튼이 기존 메인 메뉴의 게임 시작 버튼과 동일한 흐름을 타게 한다.

```gdscript
func _on_start_pressed():
    get_tree().change_scene_to_file("res://path/to/GameScene.tscn")
```

주의:

- 기존 프로젝트의 실제 게임 시작 scene 경로를 찾아서 사용한다.
- 경로를 확신할 수 없다면 Start 버튼은 생략하거나 disabled 처리해도 된다.
- 최소 필수는 Back 버튼이다.

---

## 에셋 처리 우선순위

1순위: 기존 게임에서 사용하는 실제 몬스터/아이템 sprite 재사용  
2순위: 기존 리소스 경로를 찾을 수 없으면 placeholder TextureRect / ColorRect 사용  
3순위: 임시 Label 사용

중요:

- 이번 작업에서 새 이미지를 만들 필요는 없다.
- 리소스 경로를 무리하게 추측하지 말고, 프로젝트 내 기존 enemy/item 리소스를 검색해서 사용한다.
- 경로가 불명확하면 카드 제목과 설명만 먼저 완성한다.

---

## 추천 구현 방식

가장 빠른 방식은 `HowToScreen.gd`에 카드 데이터를 배열로 선언하고, 화면 로드시 반복문으로 카드를 생성하는 방식이다.

예시 데이터 구조:

```gdscript
var cards = [
    {
        "title": "TAP",
        "targets": ["enemy_basic", "bomb"],
        "description": "기본 몬스터는 한 번 탭해서 제거하세요.\n위험 오브젝트도 타이밍에 맞춰 빠르게 반응해야 합니다."
    },
    {
        "title": "TAP TAP",
        "targets": ["enemy_fast"],
        "description": "빠른 몬스터는 두 번 공격해야 제거됩니다.\n연속 입력 타이밍을 놓치지 마세요."
    },
    {
        "title": "HOLD",
        "targets": ["enemy_armor"],
        "description": "갑옷 몬스터는 길게 눌러 처리하세요.\n게이지가 차는 느낌으로 Hold 타이밍을 익히면 됩니다."
    },
    {
        "title": "ITEMS",
        "targets": ["coin", "fever_orb", "heal"],
        "description": "Coin은 점수를 올립니다.\nFever Orb는 피버 게이지를 채웁니다.\nHeal은 체력을 회복합니다."
    },
    {
        "title": "COMBO & FEVER",
        "targets": ["combo", "fever"],
        "description": "연속으로 성공하면 콤보가 증가합니다.\n실패하거나 피격되면 콤보가 초기화됩니다.\nFever 중에는 빠른 연속 공격이 발동하고 콤보가 더 안정적으로 유지됩니다."
    }
]
```

이 방식의 장점:

- 카드 추가/수정이 쉽다.
- Scene 구조가 단순하다.
- 카드 수가 바뀌어도 UI 수정이 적다.
- 프로토타입 단계에 적합하다.

---

## 스타일 가이드

전체 분위기:

- 하이퍼 캐주얼 모바일 액션 게임
- 너무 어둡거나 복잡하지 않게
- 한눈에 규칙이 들어오게
- 카드 배경은 살짝 어두운 반투명 또는 밝은 패널
- 제목은 크고 강하게
- 설명은 짧게

권장 스타일:

```text
Title: HOW TO PLAY
Card Title: 큼, 굵게
Description: 2~3줄 이하
Card Background: 반투명 어두운 패널 또는 밝은 패널
Card Border: 있으면 좋음
Spacing: 넉넉하게
```

선택 효과:

- 선택/hover/포커스된 카드가 살짝 커지는 효과
- Fever 카드에만 약한 pulse 효과
- Hold 카드에만 간단한 게이지 tween

단, 위 효과는 시간이 남을 때만 한다.

---

## 반드시 확인할 것

구현 후 아래 항목을 확인한다.

- [ ] Mainmenu에서 HOW TO 버튼을 누르면 HOW TO 화면으로 이동한다.
- [ ] HOW TO 화면에 카드 5개가 표시된다.
- [ ] 카드 내용이 실제 변수명 매핑과 일치한다.
- [ ] `enemy_basic`, `bomb`은 한 대 처리 카드에 포함된다.
- [ ] `enemy_fast`는 두 대 처리 카드에 포함된다.
- [ ] `enemy_armor`는 Hold 카드에 포함된다.
- [ ] `coin`, `fever_orb`, `heal`은 Items 카드에 포함된다.
- [ ] Combo와 Fever 설명 카드가 있다.
- [ ] Back 버튼을 누르면 Mainmenu로 돌아간다.
- [ ] 모바일 가로 화면에서 글자가 잘리지 않는다.
- [ ] 카드가 너무 세로로 길어지지 않는다.
- [ ] ScrollContainer가 정상 동작한다.
- [ ] 기존 게임 로직이 변경되지 않는다.
- [ ] 기존 Mainmenu / Start 흐름이 깨지지 않는다.

---

## 구현 시 주의사항

- 이번 작업은 HOW TO UI 추가 작업이다. 게임 플레이 로직을 건드리지 않는다.
- 변수명/타입명은 설명 데이터와 리소스 매핑에만 사용한다.
- 기존 scene 경로, resource 경로는 프로젝트를 검색해서 정확히 사용한다.
- `Mainmenu.tscn`, 게임 시작 scene 이름은 프로젝트 실제 이름을 기준으로 맞춘다.
- 파일명 대소문자에 주의한다.
- Godot 버전에 맞는 문법을 사용한다.
- 기존 코드 스타일이 있으면 최대한 맞춘다.

---

## 권장 파일명

가능하면 아래와 같이 추가한다.

```text
res://scenes/ui/HowToScreen.tscn
res://scripts/ui/HowToScreen.gd
```

또는 현재 프로젝트의 기존 UI scene/script 폴더 규칙이 있다면 그 규칙을 따른다.

예:

```text
res://ui/HowToScreen.tscn
res://ui/HowToScreen.gd
```

---

## 최종 목표

이번 구현의 최종 목표는 아래 상태이다.

```text
사용자가 Mainmenu에서 HOW TO를 누른다.
→ 카드형 HOW TO 화면이 열린다.
→ TAP / TAP TAP / HOLD / ITEMS / COMBO & FEVER 규칙을 빠르게 이해한다.
→ Back으로 Mainmenu로 돌아가거나 Start로 게임을 시작한다.
```

구현 난이도를 낮추기 위해 처음에는 정적 카드만 완성한다.  
애니메이션, 상세 이미지, 튜토리얼 플레이는 후순위로 둔다.
