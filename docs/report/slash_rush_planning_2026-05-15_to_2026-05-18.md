# Slash Rush 러너게임 기획 통합 정리

- **정리 범위**: 2026-05-15 포함 이후 ~ 2026-05-18 현재까지, 접근 가능한 프로젝트 컨텍스트와 전체 File Library/개인 컨텍스트에서 확인된 `Slash Rush` 러너게임 관련 기획
- **작성 목적**: 흩어진 기획을 Codex에게 전달하여 실제 구현 프로젝트와 비교하고, 누락/불일치 부분을 보정하기 위한 기준 문서
- **작성 기준**: 이미지 파일, 이미지 생성용 원문 프롬프트, 순수 에셋 생성 요청은 제외. 단, 구현 비교에 필요한 에셋 산출 경로, 애니메이션 품질 기준, manifest/preview 요구사항은 요약 포함
- **주의**: 이 문서는 현재 접근 가능한 검색 결과와 파일 라이브러리 기준으로 통합한 것이다. 원시 채팅 로그 전체를 줄 단위로 직접 열람한 것은 아니므로, 실제 프로젝트 파일과 비교 시 아래 “불확실/검증 필요 항목”을 우선 확인한다.

---

## 0. 수집된 주요 출처

### 0-1. 다운로드 가능 파일/문서로 확인된 항목

| 날짜 | 파일명 | 이 문서에 반영한 내용 | 반영 방식 |
|---|---|---|---|
| 2026-05-15 09:21 UTC | `codex_samurai_running_sprite_instruction.md` | 사무라이 러닝 스프라이트 6프레임, 산출 경로, 프레임 품질 기준, manifest/preview 요구사항 | 이미지 생성 프롬프트 원문은 제외하고, 구현 비교에 필요한 출력/품질 기준만 요약 |
| 2026-05-15 16:19 UTC | `slash_rush_robot_samurai_boss_motion_codex.md` | `RobotSamuraiBoss` 모션 시스템, 공격/스턴/패배 모션, 상태 전환, 테스트 입력, 완료 기준 | 구현 지시서 내용을 비교 가능한 기획/구현 명세로 요약 |

### 0-2. 채팅/개인 컨텍스트에서 확인된 기획 항목

| 날짜 | 기획 항목 | 핵심 내용 |
|---|---|---|
| 2026-05-15 | 스테이지 배경/패럴랙스 | `Sky`, `FarLayer`, `MidLayer`, `NearLayer`, `SpeedLineLayer`, `GroundLooper`, 1280x720 배경, Sprite2D 레이어 전환 |
| 2026-05-16 | 오브젝트/패턴/난이도 | `enemy_basic`, `enemy_fast`, `enemy_armor`, `bomb`, `coin`, `heal`, `fever`, 패턴 블록 + 난이도 예산 방식 |
| 2026-05-16 | HOW TO 화면 | 모바일 가로 화면용 정적 5카드 가이드, `HowToScreen.tscn`, `HowToCard.tscn`, MainMenu HOW TO 버튼 |
| 2026-05-16 | 오브젝트 시각 유틸 | `ObjectVisualEffectUtil.gd`, fake spin, spring floating |
| 2026-05-17 | 이펙트 시스템 | `EffectManager`, item pickup, slash, fever, hit, enemy kill, hold charge effect |
| 2026-05-17 | Character Select | 프로토타입 캐릭터 선택 화면, `player1` 선택됨, `player2~5` 잠김, Coming Soon, 실제 저장/해금 미구현 |
| 2026-05-15~17 | 사무라이 러닝/보스 모션 문서 | 다운로드 파일로 생성된 Codex 지시서 포함 |

### 0-3. 제외한 항목

- 보스 파츠 PNG, 캐릭터 이미지, 배경 이미지 등 이미지 파일 자체
- 이미지 생성용 원문 프롬프트 전체
- Slash Rush와 직접 관련 없는 Godot 3D 공성 프로토타입, AI 이력서, 타로/의료 챗봇 문서, 정부사업 PDF 등
- 보안 챌린지 HTML로 보이는 `light-white-twirl-...htm`

---

# 1. 게임 전체 기획 요약

## 1-1. 게임 정체성

`Slash Rush`는 모바일 2D 러너 게임이다.
플레이어는 오른쪽을 향해 달리는 사무라이 캐릭터를 조작하고, 화면에 등장하는 적/아이템/위험 오브젝트를 **탭, 더블탭, 홀드** 같은 간단한 입력으로 판단 처리한다.

핵심은 단순 자동 러닝이 아니라 다음 세 가지다.

```text
달린다 → 오브젝트를 빠르게 판별한다 → 맞는 입력으로 처리한다 → 콤보/피버/점수 보상을 받는다
```

## 1-2. 핵심 플레이 루프

```text
게임 시작
  ↓
사무라이 자동 러닝
  ↓
스폰 패턴에 따라 적/아이템/위험 오브젝트 등장
  ↓
플레이어가 오브젝트 타입을 보고 Tap / Tap Tap / Hold / 회피 판단
  ↓
성공 시 처치/획득/콤보 증가/피버 게이지 증가
실패 시 데미지/콤보 리셋/손해
  ↓
시간 경과에 따라 난이도 상승
  ↓
점수, 콤보, 피버, 생존 시간 경쟁
```

## 1-3. MVP 우선순위

1. 러너 이동감과 배경 스크롤
2. 적/아이템/위험 오브젝트 판별
3. Tap / Tap Tap / Hold 입력 판정
4. 콤보/점수/피버
5. HOW TO 화면
6. 기본 이펙트
7. 캐릭터 선택 프로토타입
8. 사무라이 러닝 프레임/보스 모션 등 시각 확장

---

# 2. 오브젝트 기획

## 2-1. 오브젝트 종류

| ID | 유형 | 플레이어 입력/처리 | 의도 | 구현 비교 포인트 |
|---|---|---|---|---|
| `enemy_basic` | 기본 적 | Tap 1회 | 가장 기본적인 적. 초반 학습용 | 단일 탭으로 처치되는지 확인 |
| `enemy_fast` | 빠른 적 | Tap Tap / Double Tap | 빠르게 두 번 입력해야 하는 적 | 더블탭 판정 시간/쿨다운 확인 |
| `enemy_armor` | 장갑 적 | Hold / Long Click | 길게 눌러 베거나 차지 후 처리 | 홀드 시간, 홀드 이펙트, 성공/실패 판정 확인 |
| `bomb` | 위험 오브젝트 | 기본적으로 피해야 하는 함정. HOW TO에서는 Tap 계열 카드에 함께 언급된 흔적이 있음 | 썩은 사과/폭탄처럼 좋은 오브젝트와 구분해야 하는 판단 요소 | **검증 필요**: “탭으로 제거”인지 “탭하면 손해”인지 실제 구현과 맞춰야 함 |
| `coin` | 보상 아이템 | 획득/처리 시 점수 증가 | 기본 보상 | 점수 증가, pickup 이펙트 확인 |
| `heal` | 회복 아이템 | 획득/처리 시 체력 회복 | 생존 보조 | bomb와 시각적으로 명확히 구분되는지 확인 |
| `fever` / `fever_orb` | 피버 아이템 | 획득/처리 시 피버 게이지 증가 또는 피버 발동 | 고점수/콤보 유지 | 피버 게이지, 발동 이펙트, 콤보 유지 확인 |

## 2-2. 오브젝트 판별 철학

오브젝트는 “무조건 보이는 대로 베는 게임”이 아니라, 플레이어가 순간적으로 좋은 것/나쁜 것/입력 방식을 판단해야 하는 구조다.

- 기본 적은 빠른 반응을 요구한다.
- 빠른 적은 연속 입력 감각을 요구한다.
- 장갑 적은 홀드 입력을 요구한다.
- 폭탄/위험물은 보상 아이템과 혼동될 수 있으므로 시각 구분이 중요하다.
- 회복/피버/코인은 점수와 생존, 피버 흐름을 만든다.

## 2-3. bomb와 heal 구분

채팅 컨텍스트에서 `bomb`은 썩은 사과/위험 오브젝트로 언급되었고, `heal`은 회복 아이템으로 언급되었다.
둘은 시각적으로 혼동되면 안 된다.

구현 비교 시 확인할 것:

```text
bomb:
- 위험물 느낌
- 잘못 처리 시 데미지 또는 콤보 손실
- heal/coin/fever와 실루엣 또는 색감이 구분되어야 함

heal:
- 회복 아이템 느낌
- 획득 시 체력 회복
- bomb와 혼동되지 않아야 함
```

---

# 3. 입력 판정 기획

## 3-1. 입력 종류

| 입력 | 사용 대상 | 구현 포인트 |
|---|---|---|
| Tap | `enemy_basic`, 기본 처리 대상 | 모바일 터치 1회. 너무 넓은 판정은 피하되 초반에는 관대하게 |
| Tap Tap / Double Tap | `enemy_fast` | 두 번째 입력까지의 허용 시간 필요 |
| Hold / Long Click | `enemy_armor` | 최소 홀드 시간, 차지 이펙트, 해제 시 성공/실패 판정 필요 |
| 회피/무시 | `bomb` 등 위험 오브젝트 | 잘못 탭하면 손해인지, 지나가면 손해인지 규칙 정리 필요 |

## 3-2. 입력 판정 설계 방향

- 입력은 모바일 기준으로 단순해야 한다.
- “강제 복잡 조작”보다 오브젝트 판단 중심으로 설계한다.
- Tap / Double Tap / Hold의 차이를 HOW TO에서 10초 안에 이해할 수 있어야 한다.
- 성공 판정 후 약간의 after-delay 또는 입력 잠금이 필요할 수 있다.
- 좋은 오브젝트와 위험 오브젝트는 잘못 처리했을 때 손해가 발생해야 게임성이 생긴다.

## 3-3. Double Tap 판정 확인 항목

```text
- 첫 번째 탭 이후 double_tap_window 안에 두 번째 탭이 들어오는가?
- enemy_fast 외 대상에 double tap이 들어왔을 때 오작동하지 않는가?
- 연속 입력 중 콤보/이펙트가 중복 실행되지 않는가?
- 모바일 터치와 PC 테스트 입력이 같은 판정 경로를 쓰는가?
```

## 3-4. Hold 판정 확인 항목

```text
- hold_start 시 HoldChargeEffect가 붙는가?
- hold_duration이 기준 시간을 넘었을 때 성공 처리되는가?
- 중간에 손을 떼면 실패 또는 취소 처리되는가?
- enemy_armor 외 대상에 hold가 들어갔을 때 이상 동작하지 않는가?
```

---

# 4. 스폰/패턴/난이도 기획

## 4-1. 랜덤 방식

완전 랜덤 스폰이 아니라 다음 구조가 권장되었다.

```text
패턴 블록 + 난이도 예산 + 약간의 랜덤 변주
```

의도:

- 완전 랜덤은 불공정한 상황을 만들 수 있다.
- 정해진 패턴만 반복하면 금방 지루해진다.
- 패턴 블록을 만들고, 난이도 예산 안에서 섞으며, 중간중간 쉬운 패턴을 넣어 긴장을 조절한다.

## 4-2. 패턴 블록 예시

```text
Pattern A - Basic Learn
enemy_basic → coin → enemy_basic

Pattern B - Fast Reaction
enemy_basic → enemy_fast → coin

Pattern C - Hold Introduce
enemy_basic → enemy_armor → heal

Pattern D - Risk Choice
coin → bomb → enemy_basic

Pattern E - Fever Build
enemy_fast → fever_orb → enemy_basic → coin
```

## 4-3. 난이도 증가 방향

정확한 시간 값은 아직 고정되지 않은 것으로 보인다.
구현에서는 아래처럼 튜닝 가능한 단계로 두는 것이 안전하다.

| 구간 | 의도 | 스폰 구성 |
|---|---|---|
| Early | 학습 | `enemy_basic`, `coin`, 낮은 밀도 |
| Early+ | 입력 확장 | `enemy_fast`, `heal`, 간헐적 `bomb` |
| Mid | 판단 요구 | `enemy_fast`, `enemy_armor`, `bomb`, `fever_orb` |
| Late | 혼합 압박 | 모든 오브젝트, 높은 밀도, 쉬운 패턴 완충 |
| Fever/Bonus | 보상 구간 | 코인/피버 보상, 시각 효과 강화 |

## 4-4. 구현 비교 포인트

```text
- SpawnManager가 완전 랜덤만 사용하고 있지 않은가?
- pattern block 또는 wave table이 존재하는가?
- 시간에 따라 difficulty budget이 증가하는가?
- 쉬운 패턴이 중간중간 삽입되는가?
- bomb/heal/fever가 너무 초반부터 과도하게 나오지 않는가?
- 모바일 화면 기준 반응 가능한 간격을 유지하는가?
```

---

# 5. 점수/콤보/피버 기획

## 5-1. 점수 구조

기본 방향:

```text
성공 처리 → 기본 점수
연속 성공 → 콤보 증가
콤보 증가 → 점수 배율 또는 추가 점수
피버 진입 → 보너스/콤보 유지/시각 강화
실패/위험물 오처리 → 콤보 리셋 또는 손해
```

## 5-2. 콤보

- 적을 올바른 입력으로 처리하면 콤보가 증가한다.
- 아이템 획득도 콤보 유지 또는 증가에 기여할 수 있다.
- 실패, 미스, 잘못된 입력, 폭탄 처리 등은 콤보를 리셋할 수 있다.
- Fever 상태에서는 콤보가 유지되거나 안정화되는 방향이 언급되었다.

## 5-3. 피버

피버는 단순 이펙트가 아니라 게임 흐름을 바꾸는 보상 상태다.

가능한 규칙:

```text
fever_orb 획득 → fever gauge 증가
fever gauge max → fever mode 시작
fever mode 중:
  - 콤보 유지 또는 리셋 완화
  - 점수 보너스
  - 화면 이펙트 강화
  - 더 화려한 사운드/파티클
```

## 5-4. 구현 비교 포인트

```text
- combo_count가 연속 성공에 따라 증가하는가?
- 실패 시 combo_count가 리셋되는가?
- fever_gauge 또는 fever_state가 존재하는가?
- fever 중 점수/콤보/이펙트 보너스가 실제로 적용되는가?
- UI에 score/combo/fever 상태가 명확히 표시되는가?
```

---

# 6. 시각 이펙트 기획

## 6-1. 전체 이펙트 방향

Godot 4 2D 기준으로 다음 구성이 권장되었다.

- `GPUParticles2D`: 아이템 획득, 몬스터 처치, 피버 파티클
- `AnimatedSprite2D` 또는 Sprite Sheet + `AnimationPlayer`: slash, item, fever aura
- `Tween` / `AnimationPlayer`: 점수 팝업, 아이템 scale/fade, 화면 흔들림
- Shader: white flash, screen color distortion, aura, afterimage
- `EffectManager`: 이펙트 호출을 중앙 집중화

## 6-2. EffectManager 권장 API

```gdscript
EffectManager.play_coin_pickup(position)
EffectManager.play_heal_pickup(position)
EffectManager.play_fever_pickup(position)
EffectManager.play_enemy_hit(position)
EffectManager.play_enemy_kill(position)
EffectManager.play_slash(position, direction)
EffectManager.play_fever_start()
EffectManager.play_hit_flash()
```

채팅 컨텍스트에서 명시적으로 확인된 함수명은 아래 4개다.

```gdscript
play_coin_pickup()
play_heal_pickup()
play_fever_pickup()
play_enemy_hit()
```

위 나머지 함수는 구현 비교/확장용 제안으로 두되, 실제 프로젝트에 이미 다른 이름이 있으면 기존 이름을 우선한다.

## 6-3. 아이템 획득 이펙트

```text
- Tween으로 scale up/down 또는 fade
- 작은 GPUParticles2D burst
- score text popup
- 너무 오래 남지 않게 0.3~0.6초 내외 권장
```

## 6-4. Slash / 공격 이펙트

```text
- Sprite animation 또는 AnimatedSprite2D 사용
- 적중 시 짧은 흰색 flash 또는 hit spark
- enemy_fast / enemy_armor는 성공 입력이 다르므로 이펙트 강도 차이를 줄 수 있음
```

## 6-5. Fever 이펙트

```text
- screen flash
- aura AnimatedSprite2D
- particles
- camera shake
- 색감 강화 또는 후광
```

## 6-6. Hit / Enemy Kill 이펙트

```text
- enemy hit: white flash shader + camera shake
- enemy kill: 짧은 particles + fading sprite
- 적 처치 후 오브젝트는 남지 않도록 cleanup
```

## 6-7. HoldChargeEffect

`enemy_armor` 또는 홀드 입력용 차지 이펙트.

권장 씬 구조:

```text
HoldChargeEffect.tscn (Node2D)
  ├─ BodyAuraSprite2D
  ├─ ChargeRingSprite2D
  ├─ GPUParticles2D
  └─ AnimationPlayer
```

사용 방식:

```text
hold 시작 → player 또는 대상 근처에 HoldChargeEffect 표시
hold 유지 → 링/오라/파티클 강화
hold 성공 → slash/hit 이펙트와 함께 제거
hold 취소/실패 → 빠르게 fade out 후 제거
```

## 6-8. ObjectVisualEffectUtil

별도 `CollectibleItem.gd`나 `FloatingMotion.gd`를 바로 추가하기보다는, 우선 `ObjectVisualEffectUtil.gd` 같은 유틸로 공통 시각 효과를 관리하는 방향이 제안되었다.

### fake spin

```gdscript
apply_fake_spin_x(
    target,
    time,
    base_scale,
    spin_speed,
    min_scale_x_ratio,
    max_scale_x_ratio
)
```

의도:

- 2D 스프라이트가 좌우로 도는 것처럼 보이게 `scale.x`를 조절
- `scale.x`가 0에 가까워지면 깜빡이거나 뒤집힘이 부자연스러우므로 최소 비율 유지

### floating spring

```gdscript
calculate_floating_spring_y(
    delta,
    time,
    base_y,
    current_offset_y,
    velocity_y,
    amplitude,
    speed,
    spring_strength,
    damping
)
```

의도:

- 아이템이 단순 sin으로 딱딱하게 뜨는 것이 아니라, 스프링 느낌으로 자연스럽게 떠 있게 함
- 코인/회복/피버 아이템에 적용 가능

---

# 7. 배경/패럴랙스 기획

## 7-1. 현재/목표 레이어 구조

기존 구조:

```text
Sky fixed
FarLayer
MidLayer
NearLayer
SpeedLineLayer
GroundLooper
```

목표:

- 기존 코드 드로잉 `Polygon2D` / `Line2D` 기반 배경을 이미지 기반 `Sprite2D` 레이어로 교체
- 단, `SpeedLineLayer`는 기존 `Line2D`를 유지할 수 있음
- `GroundLooper`는 배경 패럴랙스에 포함하지 않고 별도 루프 처리

## 7-2. 권장 배경 해상도

```text
1280 x 720
```

Sky는 1장 고정 배경으로 두고, 나머지 레이어는 반복 가능한 세그먼트로 구성한다.

## 7-3. 준비된 배경 파일 경로

채팅 컨텍스트에서 확인된 로컬 경로:

```text
/Users/switch/Development/game/godot_games/SlashRush/assets/background/stage1
```

파일:

```text
sky_static.png
far_mountains_01.png
mid_structures_01.png
near_foreground_01.png
ground_tile_01.png
```

## 7-4. 레이어별 의도와 패럴랙스 factor

| 레이어 | 역할 | factor | 구현 포인트 |
|---|---:|---:|---|
| `Sky` | 고정 하늘 | 0 | 전체 화면 덮는 Sprite2D 또는 TextureRect |
| `FarLayer` | 먼 산/원경 | 0.24 | 느리게 움직임 |
| `MidLayer` | 중경 구조물 | 0.58 | 중간 속도 |
| `NearLayer` | 근경 장식 | 1.12 | 플레이어 속도보다 살짝 빠르게 |
| `SpeedLineLayer` | 속도감 | 1.42 | 기존 Line2D 유지 가능 |
| `GroundLooper` | 바닥 타일 | 별도 처리 | 충돌/발 위치 기준과 연결될 수 있으므로 배경 패럴랙스와 분리 |

## 7-5. 레이어 Y 배치 가이드

```text
FarLayer: 화면 높이 0.42 ~ 0.50 지점
MidLayer: 화면 높이 0.48 ~ 0.58 지점
NearLayer: 화면 높이 0.68 ~ 0.78 지점
GroundLooper: 하단 바닥 기준
```

## 7-6. 구현 방식

```text
1. 각 레이어에 Sprite2D 세그먼트 2~3개를 배치한다.
2. texture width를 기준으로 x 위치를 반복 보정한다.
3. 기존 process_scroll 루프는 유지한다.
4. 이미지 로드 실패 시 빈 레이어 또는 기존 드로잉 fallback으로 게임이 깨지지 않게 한다.
5. GroundLooper는 별도 루프 로직으로 처리한다.
```

## 7-7. 구현 비교 포인트

```text
- Sky가 스크롤되지 않는가?
- Far/Mid/Near가 서로 다른 속도로 움직이는가?
- SpeedLineLayer가 너무 강해서 오브젝트 가독성을 해치지 않는가?
- GroundLooper가 배경 패럴랙스 로직과 섞이지 않는가?
- 이미지 없을 때 에러가 아니라 fallback 처리되는가?
- 1280x720 모바일 가로 기준에서 빈 공간이 보이지 않는가?
```

---

# 8. HOW TO 화면 기획

## 8-1. 목적

신규 사용자가 10초 안에 조작법을 이해해야 한다.
MVP에서는 애니메이션 튜토리얼이 아니라 **정적 5카드 가이드**가 적합하다.

## 8-2. 화면 구조

```text
MainMenu
  └─ HOW TO 버튼
        ↓
HowToScreen.tscn
  ├─ Title
  ├─ 카드 리스트 또는 가로 스크롤 영역
  │    ├─ HowToCard.tscn x 5
  └─ Back 버튼
```

## 8-3. 카드 구성

| 카드 | 제목 | 설명 |
|---|---|---|
| 1 | TAP | `enemy_basic`, `bomb` 등 단일 탭 계열 오브젝트 설명. 단, bomb은 위험 오브젝트이므로 실제 규칙과 표현 정합성 확인 필요 |
| 2 | TAP TAP | `enemy_fast`는 빠르게 두 번 입력해야 함 |
| 3 | HOLD | `enemy_armor`는 길게 눌러 처리 |
| 4 | ITEMS | `coin`, `fever_orb`, `heal` 설명 |
| 5 | COMBO | 성공 시 콤보 증가, 실패 시 리셋, Fever 중 콤보 유지 또는 안정화 |

## 8-4. 모바일 가로 화면 UX

- 카드형 가이드북처럼 구성한다.
- 한 화면에 2~3개 카드가 보이면 충분하다.
- 페이지 전환 애니메이션보다 정적 배치가 MVP에 적합하다.
- 텍스트는 짧게, 아이콘/오브젝트 이미지를 중심으로 보여준다.

## 8-5. 구현 비교 포인트

```text
- MainMenu에 HOW TO 버튼이 있는가?
- HowToScreen.tscn이 별도 씬으로 존재하는가?
- HowToCard.tscn 또는 카드 컴포넌트가 존재하는가?
- 5개 카드가 모두 표시되는가?
- Back 버튼으로 MainMenu로 돌아갈 수 있는가?
- 모바일 가로 화면에서 글자가 작거나 잘리지 않는가?
- bomb 규칙 설명이 실제 구현과 일치하는가?
```

---

# 9. Character Select 화면 기획

## 9-1. 목적

MVP 본 게임 전에 캐릭터 선택 화면의 프로토타입을 만든다.
실제 해금/저장/능력치 시스템까지 구현하지 않는다.

## 9-2. 기본 상태

```text
player1: SELECTED
player2: LOCKED
player3: LOCKED
player4: LOCKED
player5: LOCKED
last card: Coming Soon
```

## 9-3. UX 방향

- 모바일 가로 화면 기준 1줄 가로 스크롤 카드
- 각 캐릭터 카드는 세로 비율 이미지 영역을 가진다.
- 현재 선택된 캐릭터는 `SELECTED` 상태로 표시한다.
- 잠긴 캐릭터는 `LOCKED` 상태로 표시한다.
- 마지막 카드는 `Coming Soon`으로 표시한다.

## 9-4. 기능 범위

구현하는 것:

```text
- Character Select 화면 진입
- player1 선택됨 표시
- player2~5 잠김 표시
- Coming Soon 카드 표시
- Back 버튼
- 카드 클릭 시 MessageLabel 또는 안내 메시지 표시
```

구현하지 않는 것:

```text
- 실제 캐릭터 변경 저장
- 해금 조건
- 캐릭터별 능력치
- 스킨 구매
- 영구 저장
```

## 9-5. 구현 비교 포인트

```text
- MainMenu에서 Character Select로 이동 가능한가?
- Back 버튼이 정상 동작하는가?
- player1만 selected인가?
- player2~5는 locked인가?
- Coming Soon 카드가 있는가?
- 잠긴 캐릭터 선택 시 안내 메시지가 뜨는가?
- 실제 저장/해금 로직을 과하게 만들지 않았는가?
```

---

# 10. 사무라이 러닝 스프라이트 기획

> 출처: `codex_samurai_running_sprite_instruction.md`  
> 이미지 생성 프롬프트 원문은 제외하고, 구현 비교에 필요한 결과물/규칙만 요약한다.

## 10-1. 목표

모바일 2D 러너 게임에서 사용할 수 있는 **오른쪽 방향 사무라이 러닝 루프 6프레임**을 만든다.

캐릭터 정체성:

```text
- chibi proportions
- pink ponytail hairstyle
- pink kimono top
- dark hakama
- sandals
- katana and scabbard
- right-facing direction
- 2D sprite / game illustration style
```

## 10-2. 동작 핵심

- 칼은 뽑지 않는다.
- 칼은 칼집에 들어가 있어야 한다.
- 한 손은 항상 칼 손잡이를 잡고 있어야 한다.
- 다른 손은 칼집 근처 또는 몸 가까이에 있어야 한다.
- 상체는 낮고 앞으로 기울어진 발도 준비 자세다.
- 다리는 프레임마다 명확히 달려야 한다.
- 일반 달리기처럼 팔을 크게 흔들면 안 된다.

## 10-3. 최종 산출물

```text
assets/sprites/samurai/run/frame_01.png
assets/sprites/samurai/run/frame_02.png
assets/sprites/samurai/run/frame_03.png
assets/sprites/samurai/run/frame_04.png
assets/sprites/samurai/run/frame_05.png
assets/sprites/samurai/run/frame_06.png
assets/sprites/samurai/run/run_preview.gif 또는 run_preview.html
assets/sprites/samurai/run/manifest.json
```

## 10-4. 프레임 생성/연결 방식

```text
frame_01: ImageA + ImageB 참조
frame_02: ImageA + ImageB + frame_01 참조
frame_03: ImageA + ImageB + frame_02 참조
frame_04: ImageA + ImageB + frame_03 참조
frame_05: ImageA + ImageB + frame_04 참조
frame_06: ImageA + ImageB + frame_05 참조
```

단, 직전 프레임만 계속 참조해서 얼굴/비율/복장이 변형되면, 항상 ImageA와 ImageB를 우선 기준으로 삼고 직전 프레임은 동작 흐름 참고로만 약하게 사용한다.

## 10-5. 프레임별 동작 요약

| 프레임 | 동작 의도 |
|---|---|
| `frame_01` | 앞/오른쪽 다리가 착지, 뒤/왼쪽 다리가 뒤로 뻗음, 빠른 착지 스텝 |
| `frame_02` | 앞/오른쪽 다리가 체중을 받고 굽힘, 뒤/왼쪽 다리가 회수 시작, 충격 흡수 |
| `frame_03` | 뒤/왼쪽 다리가 강하게 밀어냄, 추진 단계 |
| `frame_04` | 양다리가 몸 아래를 통과, 공중 또는 공중 직전 전환 |
| `frame_05` | frame_01의 반대 리듬, 두 번째 착지 스텝 |
| `frame_06` | 체중을 다시 받는 압축 단계, frame_01로 자연스럽게 연결 |

## 10-6. 품질 기준

```text
- 한 장에 캐릭터 1명
- 투명 배경 PNG
- 오른쪽 방향 사이드뷰 또는 약한 3/4 사이드뷰
- 같은 캔버스 크기
- 같은 캐릭터 크기
- 같은 기준점/발 위치 정렬
- 10~12 FPS 반복 재생 시 자연스러운 달리기
- 배경, 바닥 그림자, 텍스트, 장식 오브젝트 금지
```

## 10-7. manifest.json 예시

```json
{
  "name": "samurai_run_iai_ready",
  "fps": 12,
  "loop": true,
  "direction": "right",
  "frames": [
    "frame_01.png",
    "frame_02.png",
    "frame_03.png",
    "frame_04.png",
    "frame_05.png",
    "frame_06.png"
  ],
  "notes": "Right-facing iai-ready samurai running loop. Sword remains sheathed. One hand grips katana handle."
}
```

## 10-8. run_preview.html 요구사항

```text
- 6장의 이미지를 순서대로 반복 재생
- 기본 FPS 12
- 배경은 투명 또는 체크보드
- 재생/정지 버튼은 선택사항
- 이미지 경로는 frame_01.png ~ frame_06.png 기준
```

## 10-9. 실패 판정

```text
- 서있는 자세처럼 보임
- 다리 동작이 거의 변하지 않음
- 칼이 뽑혀 있음
- 캐릭터가 왼쪽을 봄
- 얼굴/머리/복장이 원본과 크게 달라짐
- 일반 질주 자세처럼 팔을 크게 흔듦
- 배경이 생김
- 프레임마다 크기 차이가 큼
```

## 10-10. 구현 비교 포인트

```text
- frame_01.png ~ frame_06.png가 실제로 존재하는가?
- manifest.json이 존재하는가?
- run_preview.gif 또는 run_preview.html이 존재하는가?
- 프레임이 10~12 FPS로 자연스럽게 이어지는가?
- 칼이 계속 칼집에 있는가?
- 한 손이 계속 칼 손잡이를 잡고 있는가?
```

---

# 11. RobotSamuraiBoss 모션 기획

> 출처: `slash_rush_robot_samurai_boss_motion_codex.md`

## 11-1. 작업 목적

현재 `RobotSamuraiBoss`는 IDLE 모션만 구현된 상태로 전제되었다.
이번 작업은 보스 전투 완성이 아니라, 보스가 살아 움직이는 것처럼 보이도록 **상태별 모션 구조를 확장**하는 것이다.

구현 범위:

```text
- 오른팔 내려찍기 모션
- 왼팔 횡베기 모션
- 코어 차지 모션
- 스턴 모션
- 패배/사망 모션
- 상태 전환 구조
- 나중에 hitbox, 이펙트, 카메라 쉐이크, 데미지 판정을 붙일 수 있는 확장 지점
```

구현하지 않는 것:

```text
- 공격 판정 완성
- 데미지
- 체력 시스템
- 보스 AI 패턴
- 보상 드랍
```

## 11-2. 현재 IDLE 파라미터

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

## 11-3. 현재 MotionState

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

## 11-4. 기본 자세와 상태별 오프셋 분리

매 프레임 최종 포즈는 아래 구조가 되어야 한다.

```text
final_pose = base_pose + state_pose + idle_pose * idle_weight
```

구현 포인트:

```text
- _ready()에서 각 Pivot의 기본 position / rotation / scale 저장
- 상태별 오프셋을 매 프레임 계산
- IDLE breathing과 공격/스턴/패배 포즈가 충돌하지 않게 idle_weight 조절
```

## 11-5. easing 함수

공격 모션은 선형 보간만 쓰면 가벼워 보이므로 easing 사용.

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

## 11-6. AttackType 추가

```gdscript
enum AttackType {
    NONE,
    RIGHT_ARM_SLAM,
    LEFT_ARM_SWEEP,
    CORE_CHARGE
}

var current_attack_type := AttackType.NONE
```

## 11-7. 상태 흐름

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

## 11-8. 상태 전환 함수

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

## 11-9. 공격별 duration

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

## 11-10. 오른팔 내려찍기

가장 먼저 구현할 공격.
보스가 고정 총알 발사 오브젝트가 아니라 직접 몸을 움직여 압박하는 타입처럼 보여야 한다.

### 타이밍

```gdscript
right_arm_slam_windup_seconds = 0.55
right_arm_slam_strike_seconds = 0.16
right_arm_slam_recover_seconds = 0.45
```

### WINDUP

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
  약간의 후행 흔들림
```

### STRIKE

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

### RECOVER

```text
- RightArmPivot이 strike 자세에서 base 자세로 부드럽게 복귀
- BodyPivot은 작은 반동 후 base로 복귀
- CorePivot 밝기/스케일 원복
```

## 11-11. 왼팔 횡베기

오른팔 내려찍기와 다르게 가로 압박 느낌.

### 타이밍

```gdscript
left_arm_sweep_windup_seconds = 0.48
left_arm_sweep_strike_seconds = 0.22
left_arm_sweep_recover_seconds = 0.50
```

### WINDUP

```text
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

### STRIKE

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

## 11-12. 코어 차지

총알 난사보다는 “에너지를 모으는 위협 동작”에 가깝게 만든다.
실제 레이저/탄환 발사는 이번 범위가 아니다.

### 타이밍

```gdscript
core_charge_windup_seconds = 0.75
core_charge_strike_seconds = 0.25
core_charge_recover_seconds = 0.55
```

### WINDUP

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

### STRIKE

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

## 11-13. STUN 모션

스턴은 반드시 구현해야 한다.
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

스턴 중 idle은 거의 섞지 않는다.

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

## 11-14. DEFEATED 모션

MVP에서는 폭발 애니메이션 없이도 된다.
파츠가 무너지는 느낌만 줘도 충분하다.

### 타이밍

```gdscript
defeated_seconds = 1.4
```

### 구현 방향

```text
- DEFEATED 진입 후 다른 attack/stun으로 전환되지 않음
- 충돌/hitbox는 나중에 disable 처리 위치를 남김
- 몸통/팔/머리/천 파츠가 무너지는 느낌
- 너무 과한 코미디 모션이 되지 않도록 무겁게 처리
```

## 11-15. 테스트 입력

MVP 개발 편의를 위해 PC 테스트 입력을 임시로 추가할 수 있다.
단, 모바일 실제 조작과 섞이지 않도록 `debug` 또는 `devtest` 조건을 둔다.

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

InputMap이 없다면 임시 키 입력:

```text
1: RIGHT_ARM_SLAM
2: LEFT_ARM_SWEEP
3: CORE_CHARGE
4: STUN
5: DEFEATED
```

## 11-16. 구현 우선순위

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

## 11-17. 완료 기준

```text
- 기존 IDLE 모션이 깨지지 않음
- 보스가 IDLE 상태에서 자연스럽게 호흡
- 테스트 입력으로 오른팔 내려찍기 실행
- 테스트 입력으로 왼팔 횡베기 실행
- 테스트 입력으로 코어 차지 실행
- 테스트 입력으로 스턴 실행
- 테스트 입력으로 패배 모션 실행
- 공격 중 IDLE 모션이 너무 강하게 섞이지 않음
- 공격 모션 후 자연스럽게 IDLE 복귀
- STUN 후 자연스럽게 IDLE 복귀
- DEFEATED 상태에서는 다른 공격/스턴으로 전환되지 않음
- 기존 플레이어 조작, 배경, 게임 루프가 깨지지 않음
- 공격 판정, 데미지, 보스 AI, 체력 시스템은 아직 구현하지 않음
```

---

# 12. Codex에게 전달할 구현 비교 체크리스트

## 12-1. 프로젝트 전체 파일/기능 확인

```text
[게임 기본]
- Godot 4.x 프로젝트인가?
- 모바일 가로 화면 기준인가?
- 플레이어가 오른쪽 방향 러너로 동작하는가?
- 배경/바닥 스크롤이 작동하는가?

[오브젝트]
- enemy_basic / enemy_fast / enemy_armor / bomb / coin / heal / fever_orb 또는 fever가 존재하는가?
- 각 오브젝트 타입에 맞는 입력/보상/패널티가 연결되어 있는가?

[입력]
- Tap / Double Tap / Hold가 구분되는가?
- 모바일 터치와 PC 테스트 입력이 같은 로직을 공유하는가?
- 입력 후 중복 처리 방지 로직이 있는가?

[스폰]
- 완전 랜덤이 아니라 pattern block 또는 difficulty budget 구조가 있는가?
- 시간 경과에 따라 난이도가 상승하는가?
- 쉬운 패턴이 중간에 삽입되는가?

[점수/콤보/피버]
- 점수 증가가 성공 처리와 연결되어 있는가?
- 콤보 증가/리셋이 있는가?
- 피버 게이지/피버 상태가 있는가?
- Fever 중 콤보/점수/이펙트가 강화되는가?

[이펙트]
- EffectManager 또는 유사한 중앙 이펙트 관리가 있는가?
- coin/heal/fever/enemy hit 이펙트가 분리되어 있는가?
- HoldChargeEffect가 존재하거나 hold 시각 피드백이 있는가?
- ObjectVisualEffectUtil 같은 공통 유틸이 있는가?

[배경]
- Sky / FarLayer / MidLayer / NearLayer / SpeedLineLayer / GroundLooper 구조가 있는가?
- stage1 이미지가 올바른 경로에 연결되어 있는가?
- GroundLooper가 별도 처리되는가?

[UI]
- HOW TO 버튼과 HowToScreen이 있는가?
- 5개 가이드 카드가 있는가?
- Character Select 프로토타입이 있는가?

[러닝 프레임]
- assets/sprites/samurai/run/frame_01.png ~ frame_06.png가 있는가?
- manifest.json과 preview 파일이 있는가?

[보스]
- RobotSamuraiBoss에 AttackType과 상태 전환이 추가되어 있는가?
- RIGHT_ARM_SLAM, LEFT_ARM_SWEEP, CORE_CHARGE, STUN, DEFEATED가 테스트 가능한가?
- 공격 판정/데미지/AI를 과하게 구현하지 않았는가?
```

## 12-2. Codex 비교 요청문 초안

아래 블록을 Codex에게 전달하면 된다.

```text
너는 지금부터 Godot 4.x Slash Rush 프로젝트를 이 문서 기준으로 점검한다.

목표:
1. 실제 구현된 프로젝트 파일을 확인한다.
2. 이 문서의 기획 항목과 현재 구현 상태를 비교한다.
3. 이미 구현된 것 / 일부 구현된 것 / 누락된 것 / 기획과 충돌하는 것을 표로 정리한다.
4. 특히 오브젝트 입력 규칙, spawn pattern, combo/fever, EffectManager, HOW TO, Character Select, background parallax, samurai run assets, RobotSamuraiBoss motion을 우선 확인한다.
5. 바로 수정하지 말고 먼저 비교 리포트를 작성한다.
6. 수정이 필요한 경우, MVP 마감 기준으로 우선순위를 제안한다.

주의:
- 이미지 생성 프롬프트는 비교 대상이 아니다.
- 이미지 파일 자체의 미적 품질보다 경로, manifest, 프레임 수, preview 존재 여부를 먼저 확인한다.
- boss motion은 보스 전투 완성이 아니라 모션 시스템 확장만 비교한다.
- 공격 판정, 데미지, 체력, 보스 AI는 현재 범위 밖이다.
```

---

# 13. 불확실/검증 필요 항목

## 13-1. bomb 처리 규칙

채팅 컨텍스트에서 `bomb`은 위험 오브젝트로 확인되지만, HOW TO 카드 구성에서는 `TAP` 카드에 `enemy_basic`, `bomb`이 함께 언급된 흔적이 있다.

가능한 해석:

1. bomb도 Tap으로 제거해야 하지만 잘못 타이밍이면 피해
2. bomb은 Tap 계열 오브젝트처럼 생겼지만 누르면 손해이므로 회피/판단 대상
3. HOW TO 카드에서 단순 예시로 들어갔으나 실제 규칙과 충돌

Codex 비교 시 실제 구현을 먼저 확인하고, 기획을 한 방향으로 확정해야 한다.

## 13-2. 난이도 시간값

`Early/Mid/Late` 구간의 정확한 초 단위 기준은 검색 결과에서 확정되지 않았다.
따라서 현재는 튜닝 가능한 데이터 구조로 두는 것이 안전하다.

## 13-3. 점수 수치

점수/콤보/피버의 정확한 수치 배율은 확정 자료가 확인되지 않았다.
현재 문서는 구조 중심이다.

## 13-4. Character Select 상세 원문

Character Select 화면 지시문은 채팅 컨텍스트에서 항목과 범위가 확인되었지만, 파일 라이브러리에서 별도 다운로드 파일로 확인되지는 않았다.
따라서 이 문서에서는 확인된 설계 범위를 요약했다.

## 13-5. 전체 채팅 원문 접근 제한

이 문서는 현재 접근 가능한 개인 컨텍스트와 파일 라이브러리 검색 결과를 기반으로 한다.
프로젝트 밖 전체 채팅의 원문을 시간순으로 모두 직접 열람한 것은 아니므로, 실제 대화에서 빠진 세부 수치가 있다면 Codex 비교 후 보정해야 한다.

---

# 14. 최종 요약

`Slash Rush`의 현재 기획은 다음 축으로 정리된다.

```text
1. 모바일 2D 사무라이 러너
2. Tap / Tap Tap / Hold 입력 기반 오브젝트 판별
3. enemy_basic / enemy_fast / enemy_armor / bomb / coin / heal / fever 계열 오브젝트
4. 패턴 블록 + 난이도 예산 기반 스폰
5. score / combo / fever 보상 구조
6. Godot 4 2D EffectManager 기반 이펙트
7. Sky + Far/Mid/Near/SpeedLine + GroundLooper 배경 구조
8. 5카드 HOW TO 화면
9. 캐릭터 선택 프로토타입
10. 사무라이 러닝 6프레임 에셋 요구사항
11. RobotSamuraiBoss 모션 시스템 확장
```

Codex에게는 이 문서를 기준으로 **실제 구현 상태 비교 리포트 → 우선순위 보정 → 단계별 수정** 순서로 작업시키는 것이 가장 안전하다.
