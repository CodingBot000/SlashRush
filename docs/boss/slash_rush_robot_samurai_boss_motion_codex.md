# Slash Rush 보스 모션 구현 지시서

## 목적

현재 `RobotSamuraiBoss`는 IDLE 모션만 구현된 상태다.  
이번 작업에서는 공격 판정, 데미지, 체력 시스템, 보스 AI 패턴까지 완성하지 않는다. 목표는 **보스가 실제로 살아 움직이는 것처럼 보이도록 상태별 모션 구조를 확장**하는 것이다.

우선 구현 범위는 다음이다.

- 오른팔 내려찍기 모션
- 왼팔 횡베기 모션
- 코어 차지 모션
- 스턴 모션
- 패배/사망 모션
- 상태 전환 구조
- 나중에 hitbox, 이펙트, 카메라 쉐이크, 데미지 판정을 붙일 수 있는 확장 지점

공격 판정 자체는 이번 작업에서 만들지 않는다.  
단, 나중에 공격 판정을 연결하기 쉽도록 `ATTACK_STRIKE` 구간에 콜백/주석/확장 포인트를 남긴다.

---

## 현재 구현 상태

현재 보스에는 IDLE 모션이 구현되어 있다.

현재 파라미터 예시:

```gdscript
breath_cycle_seconds = 3.2
body_bob_amount = 17.0
body_breath_scale_amount = 0.026
head_bob_amount = 11.0
head_tilt_amount = 2.8
arm_sway_amount = 7.0
cloth_sway_amount = 6.5
core_pulse_amount = 0.085
```

현재 상태 enum:

```gdscript
enum MotionState {
	IDLE,
	ATTACK_WINDUP,
	ATTACK_STRIKE,
	ATTACK_RECOVER,
	STUN,
	DEFEATED
}

var motion_state := MotionState.IDLE
var state_time := 0.0
```

현재 `_process(delta)`는 대략 아래 구조로 흐른다.

```gdscript
func _process(delta):
	state_time += delta

	match motion_state:
		MotionState.IDLE:
			_process_idle(delta)
		MotionState.ATTACK_WINDUP:
			_process_attack_windup(delta)
		MotionState.ATTACK_STRIKE:
			_process_attack_strike(delta)
		MotionState.ATTACK_RECOVER:
			_process_attack_recover(delta)
		MotionState.STUN:
			_process_stun(delta)
		MotionState.DEFEATED:
			_process_defeated(delta)
```

---

## 중요한 구현 방향

### 1. 기본 자세와 상태별 오프셋을 분리할 것

`_ready()`에서 각 Pivot의 기본값을 저장하고, 매 프레임 다음 구조로 최종 pose를 계산한다.

```text
final_pose = base_pose + state_pose + idle_pose * idle_weight
```

IDLE 상태에서는 `idle_weight = 1.0`으로 사용한다.  
공격 중에는 `idle_weight`를 낮춰서 약한 호흡만 섞는다.  
스턴/패배 상태에서는 idle을 거의 끄거나 아주 약하게만 섞는다.

권장값:

```gdscript
IDLE: idle_weight = 1.0
ATTACK_WINDUP: idle_weight = 0.35
ATTACK_STRIKE: idle_weight = 0.05
ATTACK_RECOVER: idle_weight = 0.25
STUN: idle_weight = 0.15
DEFEATED: idle_weight = 0.0
```

### 2. Sprite2D 직접 조작보다 Pivot Node2D를 조작할 것

현재 구조는 파츠별 Pivot을 두는 방식이어야 한다.

예시:

```text
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
```

각 모션은 `BodyPivot`, `HeadPivot`, `LeftArmPivot`, `RightArmPivot`, `CorePivot`, `ClothLeftPivot`, `ClothRightPivot`의 `position`, `rotation_degrees`, `scale`, 필요 시 `modulate`를 변경한다.

### 3. 급격한 모션은 easing을 사용할 것

공격 모션은 선형 보간만 쓰면 가벼워 보인다.  
아래 easing 함수를 사용한다.

```gdscript
func _ease_in_out(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _ease_out(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)

func _ease_in(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	return t * t * t
```

---

## 공격 종류 enum 추가

기존 `MotionState`는 유지하고, 공격 종류만 별도 enum으로 추가한다.

```gdscript
enum AttackType {
	NONE,
	RIGHT_ARM_SLAM,
	LEFT_ARM_SWEEP,
	CORE_CHARGE
}

var current_attack_type := AttackType.NONE
```

상태 흐름:

```text
IDLE
 → ATTACK_WINDUP
 → ATTACK_STRIKE
 → ATTACK_RECOVER
 → IDLE

피격/패턴 실패/테스트 입력:
 → STUN
 → IDLE

HP 0 또는 테스트 입력:
 → DEFEATED
```

---

## 상태 전환 함수

아래와 같은 함수를 추가한다.

```gdscript
func start_attack(attack_type: AttackType) -> void:
	if motion_state == MotionState.DEFEATED:
		return

	current_attack_type = attack_type
	set_motion_state(MotionState.ATTACK_WINDUP)


func set_motion_state(next_state: MotionState) -> void:
	motion_state = next_state
	state_time = 0.0
	_enter_state(next_state)


func _enter_state(next_state: MotionState) -> void:
	match next_state:
		MotionState.IDLE:
			current_attack_type = AttackType.NONE
		MotionState.ATTACK_WINDUP:
			pass
		MotionState.ATTACK_STRIKE:
			# Later: enable attack hitbox here.
			pass
		MotionState.ATTACK_RECOVER:
			# Later: disable attack hitbox here.
			pass
		MotionState.STUN:
			# Later: disable all active attack hitboxes here.
			pass
		MotionState.DEFEATED:
			# Later: disable collision/hitbox here.
			pass
```

---

## 공통 duration 함수

공격별 타이밍을 분리한다.

```gdscript
func _get_windup_duration(attack_type: AttackType) -> float:
	match attack_type:
		AttackType.RIGHT_ARM_SLAM:
			return 0.55
		AttackType.LEFT_ARM_SWEEP:
			return 0.48
		AttackType.CORE_CHARGE:
			return 0.75
		_:
			return 0.5


func _get_strike_duration(attack_type: AttackType) -> float:
	match attack_type:
		AttackType.RIGHT_ARM_SLAM:
			return 0.16
		AttackType.LEFT_ARM_SWEEP:
			return 0.22
		AttackType.CORE_CHARGE:
			return 0.25
		_:
			return 0.2


func _get_recover_duration(attack_type: AttackType) -> float:
	match attack_type:
		AttackType.RIGHT_ARM_SLAM:
			return 0.45
		AttackType.LEFT_ARM_SWEEP:
			return 0.50
		AttackType.CORE_CHARGE:
			return 0.55
		_:
			return 0.45
```

---

## 상태 처리 함수 구조

```gdscript
func _process_attack_windup(delta: float) -> void:
	var duration := _get_windup_duration(current_attack_type)
	var t := _ease_in_out(state_time / duration)

	match current_attack_type:
		AttackType.RIGHT_ARM_SLAM:
			_apply_right_arm_slam_windup(t)
		AttackType.LEFT_ARM_SWEEP:
			_apply_left_arm_sweep_windup(t)
		AttackType.CORE_CHARGE:
			_apply_core_charge_windup(t)
		_:
			pass

	if state_time >= duration:
		set_motion_state(MotionState.ATTACK_STRIKE)


func _process_attack_strike(delta: float) -> void:
	var duration := _get_strike_duration(current_attack_type)
	var t := _ease_out(state_time / duration)

	match current_attack_type:
		AttackType.RIGHT_ARM_SLAM:
			_apply_right_arm_slam_strike(t)
		AttackType.LEFT_ARM_SWEEP:
			_apply_left_arm_sweep_strike(t)
		AttackType.CORE_CHARGE:
			_apply_core_charge_strike(t)
		_:
			pass

	if state_time >= duration:
		set_motion_state(MotionState.ATTACK_RECOVER)


func _process_attack_recover(delta: float) -> void:
	var duration := _get_recover_duration(current_attack_type)
	var t := _ease_in_out(state_time / duration)

	match current_attack_type:
		AttackType.RIGHT_ARM_SLAM:
			_apply_right_arm_slam_recover(t)
		AttackType.LEFT_ARM_SWEEP:
			_apply_left_arm_sweep_recover(t)
		AttackType.CORE_CHARGE:
			_apply_core_charge_recover(t)
		_:
			pass

	if state_time >= duration:
		set_motion_state(MotionState.IDLE)
```

---

# 모션 설계

## 1. 오른팔 내려찍기

가장 먼저 구현할 공격이다.  
보스가 가만히 총알만 쏘는 타입이 아니라, 직접 몸을 움직여 압박하는 타입처럼 보이게 만든다.

### 타이밍

```gdscript
right_arm_slam_windup_seconds = 0.55
right_arm_slam_strike_seconds = 0.16
right_arm_slam_recover_seconds = 0.45
```

### WINDUP 포즈

공격 전 준비 동작이다.  
오른팔을 크게 들어 올리고, 몸통은 살짝 뒤로 젖힌다.

권장 오프셋:

```text
BodyPivot:
position.x += 10
position.y -= 8
rotation_degrees += 2

HeadPivot:
position.y -= 6
rotation_degrees -= 4

RightArmPivot:
position.x += 10
position.y -= 28
rotation_degrees -= 35

LeftArmPivot:
rotation_degrees += 8

CorePivot:
scale *= 1.18

ClothLeftPivot / ClothRightPivot:
rotation_degrees += 약간의 후행 흔들림
```

### STRIKE 포즈

짧고 강하게 내려찍는다.  
이 구간은 나중에 hitbox, 충격파, 카메라 흔들림을 붙일 위치다.

권장 오프셋:

```text
BodyPivot:
position.x -= 18
position.y += 12
rotation_degrees -= 3

HeadPivot:
rotation_degrees += 3

RightArmPivot:
position.x -= 35
position.y += 48
rotation_degrees += 62

LeftArmPivot:
rotation_degrees -= 5

CorePivot:
scale *= 1.05
```

확장 지점:

```gdscript
# Later:
# - Enable right arm slam hitbox during ATTACK_STRIKE.
# - Spawn ground shockwave.
# - Apply camera shake.
# - Play slam SFX.
```

### RECOVER 포즈

팔이 살짝 튕긴 뒤 원래 위치로 돌아간다.

권장:

```text
RightArmPivot:
strike 자세에서 base 자세로 부드럽게 복귀

BodyPivot:
작은 반동 후 base로 복귀

CorePivot:
밝기/스케일 원복
```

---

## 2. 왼팔 횡베기

두 번째 공격이다.  
오른팔 내려찍기와 다르게 가로 압박 느낌을 준다.

### 타이밍

```gdscript
left_arm_sweep_windup_seconds = 0.48
left_arm_sweep_strike_seconds = 0.22
left_arm_sweep_recover_seconds = 0.50
```

### WINDUP 포즈

```text
BodyPivot:
position.x += 8
rotation_degrees += 3

HeadPivot:
rotation_degrees -= 3

LeftArmPivot:
position.x += 22
position.y -= 10
rotation_degrees += 34

RightArmPivot:
rotation_degrees -= 8

CorePivot:
scale *= 1.12
```

### STRIKE 포즈

```text
BodyPivot:
position.x -= 20
rotation_degrees -= 5

LeftArmPivot:
position.x -= 45
position.y += 6
rotation_degrees -= 58

RightArmPivot:
rotation_degrees += 5

ClothLeftPivot / ClothRightPivot:
순간적으로 크게 흔들림
```

확장 지점:

```gdscript
# Later:
# - Enable wide front sweep hitbox.
# - Spawn red slash effect.
# - Play sweep SFX.
```

### RECOVER 포즈

왼팔이 원위치로 돌아오고, 천은 조금 더 늦게 흔들리도록 한다.

---

## 3. 코어 차지

총알 난사보다는 “에너지를 모으는 위협 동작”에 가깝게 만든다.  
이번 작업에서는 실제 레이저/탄환 발사는 만들지 않아도 된다.

### 타이밍

```gdscript
core_charge_windup_seconds = 0.75
core_charge_strike_seconds = 0.25
core_charge_recover_seconds = 0.55
```

### WINDUP 포즈

```text
BodyPivot:
position.y -= 10
scale.y *= 1.03

HeadPivot:
position.y -= 5
rotation_degrees += sin(state_time * 18.0) * 1.5

LeftArmPivot:
position.x -= 12
rotation_degrees -= 14

RightArmPivot:
position.x += 12
rotation_degrees += 14

CorePivot:
scale: 1.0 → 1.45
modulate 밝기 증가
```

### STRIKE 포즈

```text
CorePivot:
scale *= 1.65 후 빠르게 1.15로 감소

BodyPivot:
position.y += 10

HeadPivot:
작게 흔들림

LeftArmPivot / RightArmPivot:
벌렸다가 살짝 닫힘
```

확장 지점:

```gdscript
# Later:
# - Spawn core beam or shockwave.
# - Apply screen flash.
# - Play charge release SFX.
```

### RECOVER 포즈

코어 크기와 밝기를 원복한다.  
몸통은 무거운 숨을 내쉬는 것처럼 천천히 IDLE 자세로 돌아간다.

---

## 4. STUN 모션

스턴은 반드시 구현한다.  
보스가 맞았을 때 반응이 없으면 완성도가 크게 떨어진다.

### 타이밍

```gdscript
stun_seconds = 0.75
```

### 모션

```text
BodyPivot:
position.x += sin(state_time * 42.0) * 4
position.y += sin(state_time * 35.0) * 3
rotation_degrees += sin(state_time * 30.0) * 2

HeadPivot:
rotation_degrees += sin(state_time * 40.0) * 7
position.y += 8

LeftArmPivot:
rotation_degrees += 18
position.y += 16

RightArmPivot:
rotation_degrees -= 18
position.y += 16

CorePivot:
scale *= 0.85 + abs(sin(state_time * 20.0)) * 0.25
modulate.a = 0.45 ~ 1.0 반복

ClothLeftPivot / ClothRightPivot:
평소보다 크게 흔들림
```

스턴 중에는 idle을 거의 섞지 않는다.

```gdscript
idle_weight = 0.15
```

상태 종료:

```gdscript
if state_time >= stun_seconds:
	set_motion_state(MotionState.IDLE)
```

테스트용 함수:

```gdscript
func start_stun() -> void:
	if motion_state == MotionState.DEFEATED:
		return

	current_attack_type = AttackType.NONE
	set_motion_state(MotionState.STUN)
```

---

## 5. DEFEATED 모션

MVP에서는 폭발 애니메이션 없이도 된다.  
파츠가 무너지는 느낌만 줘도 충분하다.

### 타이밍

```gdscript
defeated_seconds = 1.4
```

### 모션

`t = clamp(state_time / defeated_seconds, 0.0, 1.0)` 기준으로 아래처럼 진행한다.

```text
BodyPivot:
position.y += t * 45
rotation_degrees += t * 8

HeadPivot:
position.x -= t * 35
position.y += t * 60
rotation_degrees -= t * 35

LeftArmPivot:
position.x -= t * 70
position.y += t * 80
rotation_degrees += t * 55

RightArmPivot:
position.x += t * 70
position.y += t * 80
rotation_degrees -= t * 55

CorePivot:
scale = lerp(1.0, 0.1, t)
modulate.a = lerp(1.0, 0.0, t)

ClothLeftPivot / ClothRightPivot:
position.y += t * 70
rotation_degrees += sin(t * PI * 2.0) * 10
```

마지막 처리:

- `queue_free()`를 바로 호출하지 말고, 일단 화면에서 사라지거나 멈추는 식으로 처리한다.
- 나중에 폭발 이펙트를 붙일 수 있도록 아래 주석을 남긴다.

```gdscript
# Later:
# - Spawn explosion particles.
# - Drop reward.
# - Notify stage manager that boss is defeated.
```

테스트용 함수:

```gdscript
func start_defeated() -> void:
	current_attack_type = AttackType.NONE
	set_motion_state(MotionState.DEFEATED)
```

---

# 테스트 입력

MVP 개발 편의를 위해 PC에서 테스트 가능한 입력을 임시로 추가해도 된다.  
단, 모바일 실제 조작과 섞이지 않도록 `debug` 또는 `devtest` 조건을 걸거나 명확한 주석을 남긴다.

예시:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_boss_slam"):
		start_attack(AttackType.RIGHT_ARM_SLAM)
	elif event.is_action_pressed("debug_boss_sweep"):
		start_attack(AttackType.LEFT_ARM_SWEEP)
	elif event.is_action_pressed("debug_boss_core"):
		start_attack(AttackType.CORE_CHARGE)
	elif event.is_action_pressed("debug_boss_stun"):
		start_stun()
	elif event.is_action_pressed("debug_boss_defeated"):
		start_defeated()
```

InputMap이 없다면 임시로 키 입력을 직접 받아도 된다.

권장 테스트 키:

```text
1: RIGHT_ARM_SLAM
2: LEFT_ARM_SWEEP
3: CORE_CHARGE
4: STUN
5: DEFEATED
```

주의:

- 테스트 입력은 반드시 주석 처리하거나 dev 전용으로 구분한다.
- 기존 플레이어 입력을 깨지 말 것.
- 기존 dev tool이 있다면 그 흐름을 최대한 유지한다.

---

# 구현 우선순위

아래 순서대로 작업한다.

```text
1. AttackType enum 추가
2. set_motion_state(), start_attack(), start_stun(), start_defeated() 추가
3. duration 함수 추가
4. RIGHT_ARM_SLAM 구현
5. STUN 구현
6. LEFT_ARM_SWEEP 구현
7. DEFEATED 구현
8. CORE_CHARGE 구현
9. 테스트 입력 추가
10. 실행 후 파츠 위치/회전/스케일 미세 조정
```

가장 중요한 것은 `RIGHT_ARM_SLAM`과 `STUN`이다.  
이 두 개만 제대로 구현되어도 보스가 살아있는 느낌이 크게 올라간다.

---

# 완료 기준

작업 완료 후 다음을 확인한다.

- 기존 IDLE 모션이 깨지지 않는다.
- 보스가 IDLE 상태에서 자연스럽게 호흡한다.
- 테스트 입력으로 오른팔 내려찍기 모션이 실행된다.
- 테스트 입력으로 왼팔 횡베기 모션이 실행된다.
- 테스트 입력으로 코어 차지 모션이 실행된다.
- 테스트 입력으로 스턴 모션이 실행된다.
- 테스트 입력으로 패배 모션이 실행된다.
- 공격 중에는 IDLE 모션이 너무 강하게 섞이지 않는다.
- 공격 모션 후 자연스럽게 IDLE로 복귀한다.
- STUN 후 자연스럽게 IDLE로 복귀한다.
- DEFEATED 상태에서는 다른 공격/스턴으로 전환되지 않는다.
- 기존 플레이어 조작, 배경, 게임 루프가 깨지지 않는다.
- 공격 판정, 데미지, 보스 AI, 체력 시스템은 아직 구현하지 않는다.

---

# 작업 후 보고할 내용

작업 완료 후 아래 내용을 요약해서 보고한다.

```text
1. 생성/수정한 파일 목록
2. 추가한 enum / 함수 목록
3. 각 모션의 duration 값
4. 테스트 키 또는 테스트 방법
5. 실제 실행 후 확인한 내용
6. 아직 구현하지 않은 것
7. 다음 단계에서 hitbox/공격 판정을 붙일 위치
```

---

# 주의사항

- 이번 작업은 “보스 전투 완성”이 아니라 “보스 모션 시스템 확장”이다.
- 공격 판정, 체력, 데미지, 보스 AI, 보상 드랍은 구현하지 않는다.
- 기존 구조를 크게 갈아엎지 않는다.
- 파츠별 Pivot 구조를 유지한다.
- 이미지 파일 경로는 기존 경로를 그대로 사용한다.
- 모션이 과하면 장난감처럼 보이므로, STRIKE만 강하게 하고 WINDUP/RECOVER는 무겁게 처리한다.
- 보스는 총알만 쏘는 고정 오브젝트가 아니라, 몸을 직접 움직이는 위협적인 보스로 보여야 한다.
