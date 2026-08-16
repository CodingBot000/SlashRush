현재 Godot 프로젝트는 Slash Rush이다. 
보스 몬스터용 이미지 파츠를 아래 경로에 이미 넣어두었다.

경로:
 /Users/switch/Development/game/godot_games/SlashRush/assets/boss/robot_samurai

파일명:
- boss_head.png
- boss_body.png
- boss_left_arm.png
- boss_right_arm.png
- boss_core.png
- boss_cloth_left.png
- boss_cloth_right.png

이번 작업 목표:
공격 액션은 아직 만들지 않는다.
먼저 “저주받은 기계 사무라이 갑옷 보스”를 Godot에서 파츠 조립형 보스로 구성하고, 가만히 있을 때도 살아있는 것처럼 각 파츠가 자연스럽게 흔들리는 idle motion만 구현한다.

중요:
- 기존 게임 구조를 크게 갈아엎지 말 것.
- 기존 플레이어, 배경, 입력, 게임 루프를 깨지 말 것.
- 보스는 일단 테스트용으로 화면 오른쪽에 등장/배치되도록 한다.
- 이번 작업에서는 공격, 데미지, 체력, 피격 판정, 보스 AI는 구현하지 않는다.
- 나중에 공격 패턴과 hitbox를 붙일 수 있도록 구조만 확장성 있게 만든다.

구현 요구사항:

1. 보스 전용 Scene 생성
가능하면 아래 경로에 새 Scene을 만든다.
- scenes/boss/RobotSamuraiBoss.tscn

루트 노드는 Node2D로 한다.
예시 구조:

RobotSamuraiBoss(Node2D)
 ├─ BodyPivot(Node2D)
 │   └─ Body(Sprite2D)
 ├─ HeadPivot(Node2D)
 │   └─ Head(Sprite2D)
 ├─ LeftArmPivot(Node2D)
 │   └─ LeftArm(Sprite2D)
 ├─ RightArmPivot(Node2D)
 │   └─ RightArm(Sprite2D)
 ├─ CorePivot(Node2D)
 │   └─ Core(Sprite2D)
 ├─ ClothLeftPivot(Node2D)
 │   └─ ClothLeft(Sprite2D)
 └─ ClothRightPivot(Node2D)
     └─ ClothRight(Sprite2D)

주의:
Sprite2D 자체를 바로 움직이기보다 Pivot Node2D를 움직이도록 구성한다.
나중에 팔 내려찍기, 머리 추적, 코어 개방 같은 애니메이션을 붙이기 쉽게 만들기 위함이다.

2. 이미지 연결
각 Sprite2D에는 아래 이미지를 연결한다.

Body:
assets/boss/robot_samurai/boss_body.png

Head:
assets/boss/robot_samurai/boss_head.png

LeftArm:
assets/boss/robot_samurai/boss_left_arm.png

RightArm:
assets/boss/robot_samurai/boss_right_arm.png

Core:
assets/boss/robot_samurai/boss_core.png

ClothLeft:
assets/boss/robot_samurai/boss_cloth_left.png

ClothRight:
assets/boss/robot_samurai/boss_cloth_right.png

3. 보스 배치 방향
이 보스는 횡스크롤 게임에서 화면 오른쪽에 있는 보스다.
플레이어를 향해 왼쪽을 바라보는 느낌이어야 한다.

이미지 자체가 3/4 side view 느낌이므로, 우선 flip_h는 사용하지 말고 원본 방향을 확인한다.
만약 게임 화면에서 보스가 반대로 보이면 RobotSamuraiBoss 루트나 각 Sprite2D에 scale.x = -1을 적용하는 방식으로 조정한다.
단, 일단은 원본 이미지 방향을 우선 사용한다.

4. 대략적인 파츠 위치
정확한 좌표는 실제 화면에서 보고 조정해도 된다.
우선 다음 컨셉으로 배치한다.

- Body는 중심
- Head는 Body보다 위쪽/왼쪽에 살짝 떠 있게 배치
- LeftArm은 몸통 왼쪽 아래
- RightArm은 몸통 오른쪽에 크게 배치
- Core는 Body 가슴 중앙에 배치
- ClothLeft, ClothRight는 몸통 하단 양쪽에 배치

보스 전체 크기는 모바일 가로 화면에서 너무 크지 않게 한다.
처음에는 루트 scale을 0.45 ~ 0.65 사이로 두고, 화면 오른쪽에 배치한다.
보스가 너무 크면 scale을 줄인다.

5. Idle Motion 스크립트 작성
아래 경로에 스크립트를 만든다.
- scripts/boss/RobotSamuraiBoss.gd
또는 프로젝트 기존 구조에 맞는 boss 스크립트 폴더가 있으면 그 구조를 따른다.

이 스크립트는 RobotSamuraiBoss 루트에 붙인다.

idle motion 요구사항:
- Body: 무겁게 호흡하듯 천천히 위아래로 움직임
- Head: 몸보다 살짝 늦게 위아래로 흔들리고, 좌우로 미세하게 기울어짐
- LeftArm: 어깨에 매달린 것처럼 천천히 회전하며 흔들림
- RightArm: LeftArm과 다른 타이밍으로 흔들림
- Core: 붉은 에너지처럼 scale이 아주 살짝 커졌다 작아지고, modulate 알파/밝기가 은은하게 변화
- ClothLeft / ClothRight: 천 조각처럼 좌우로 흔들리고 회전
- 모든 파츠가 같은 타이밍으로 움직이면 장난감처럼 보이므로, 각 파츠마다 phase/speed/amplitude를 다르게 준다.
- random jitter는 너무 강하게 쓰지 말고, sin/cos 기반으로 부드럽게 움직인다.
- 공격 애니메이션처럼 크고 빠른 움직임은 만들지 않는다. 지금은 idle 생동감만 구현한다.

예상 코드 방향:
- _ready()에서 각 Pivot의 기본 position, rotation, scale을 저장한다.
- _process(delta)에서 time += delta
- sin(time * speed + phase)를 사용해서 각 Pivot의 position.y, rotation_degrees, scale을 조금씩 변경한다.
- export var로 idle 강도를 조정할 수 있게 한다.

권장 export 변수:
- idle_enabled: bool = true
- body_bob_amount: float
- head_bob_amount: float
- arm_sway_amount: float
- cloth_sway_amount: float
- core_pulse_amount: float

6. 테스트 배치
기존 메인 게임 씬에서 보스를 바로 강하게 연결하지 말고, 안전한 방식으로 테스트한다.

가능한 방식 중 하나:
- 현재 플레이 씬에 RobotSamuraiBoss.tscn을 임시로 인스턴스한다.
- 위치는 화면 오른쪽 보스 테스트 위치로 둔다.
- 기존 플레이 흐름을 방해하지 않도록 collision, damage, attack은 비활성 상태로 둔다.
- 나중에 쉽게 제거/교체 가능하도록 주석이나 명확한 이름을 남긴다.

만약 프로젝트에 이미 enemy/boss spawn 구조가 있다면 그 구조를 크게 바꾸지 말고, 테스트용 보스 인스턴스만 추가한다.

7. z_index 정리
파츠가 자연스럽게 겹치도록 z_index를 설정한다.

권장:
- ClothLeft / ClothRight: 뒤쪽 또는 하단
- Body: 중앙
- Core: Body보다 앞
- Head: Body보다 앞 또는 같은 레벨
- Arms: Body 앞/뒤가 자연스럽게 보이도록 조정

예시:
Cloth: z_index = -2
Body: z_index = 0
Core: z_index = 2
Head: z_index = 3
Arms: z_index = 1 또는 2

실제 이미지 겹침을 보고 조정한다.

8. 완료 기준
작업 완료 후 다음을 확인한다.

- Godot 에디터에서 RobotSamuraiBoss.tscn을 열면 7개 파츠가 정상 표시된다.
- 보스가 정면을 보는 느낌이 아니라, 횡스크롤 보스처럼 화면 왼쪽을 향해 있는 느낌이어야 한다.
- 게임 실행 시 보스가 화면 오른쪽에 표시된다.
- 아무 공격을 하지 않아도 몸통, 머리, 팔, 코어, 천이 각각 다른 타이밍으로 미세하게 움직인다.
- 움직임이 너무 과장되어 장난감처럼 보이지 않아야 한다.
- 기존 플레이어 조작, 배경 스크롤, 입력이 깨지지 않는다.
- 공격/피격/체력 구현은 하지 않는다.

9. 구현 후 보고
작업 후 아래 내용을 요약해서 보고해라.
- 생성/수정한 파일 목록
- RobotSamuraiBoss.tscn 노드 구조
- idle motion에 사용한 주요 파라미터
- 보스 위치/scale 값
- 이후 공격 패턴을 붙일 때 확장하면 좋은 지점