현재 Godot 프로젝트 SlashRush의 러너 스테이지 배경을 코드 도형 기반 배경에서 이미지 기반 배경으로 교체한다.

이미지 파일은 이미 준비되어 있으며 위치는 다음과 같다.

res://assets/background/stage1/sky_static.png
res://assets/background/stage1/far_mountains_01.png
res://assets/background/stage1/mid_structures_01.png
res://assets/background/stage1/near_foreground_01.png
res://assets/background/stage1/ground_tile_01.png

현재 구조 분석:
- ParallaxScroller.gd에서 Sky, FarLayer, MidLayer, NearLayer를 생성하고 있음
- Sky는 고정 배경
- FarLayer는 factor 0.24
- MidLayer는 factor 0.58
- NearLayer는 factor 1.12
- GroundLooper.gd는 GroundTile 8개를 코드 도형으로 생성해서 바닥을 루프시키고 있음

작업 목표:
1. 기존 ParallaxScroller.gd의 스크롤 구조와 process_scroll 방식은 유지한다.
2. 기존 Polygon2D / Line2D로 생성하던 임시 배경 도형 중 Sky, FarLayer, MidLayer, NearLayer 부분을 이미지 Sprite2D 기반으로 교체한다.
3. GroundLooper.gd의 바닥 도형도 ground_tile_01.png 기반 Sprite2D 반복 구조로 교체한다.
4. 플레이어, 장애물, 보스전, 입력, 게임 속도, 충돌 로직은 수정하지 않는다.

구현 상세:

[ParallaxScroller.gd 수정]

1. 다음 이미지 경로를 상수로 선언한다.

const SKY_TEXTURE_PATH := "res://assets/background/stage1/sky_static.png"
const FAR_TEXTURE_PATH := "res://assets/background/stage1/far_mountains_01.png"
const MID_TEXTURE_PATH := "res://assets/background/stage1/mid_structures_01.png"
const NEAR_TEXTURE_PATH := "res://assets/background/stage1/near_foreground_01.png"

2. 기존 Sky 생성 로직에서 Polygon2D로 파란 하늘을 그리던 부분을 제거하고, sky_static.png를 사용하는 Sprite2D 또는 TextureRect로 교체한다.

권장 방식:
- Sky 노드 아래에 Sprite2D를 1개 생성
- texture = load(SKY_TEXTURE_PATH)
- centered = false
- position = Vector2.ZERO
- 화면 크기에 맞춰 scale 조정
- viewport 크기를 기준으로 화면 전체를 덮도록 한다.

3. FarLayer, MidLayer, NearLayer는 각각 Sprite2D 세그먼트를 여러 개 생성해서 기존 스크롤 로직으로 움직이도록 만든다.

권장 구조:
- 각 레이어마다 텍스처를 load한다.
- 텍스처의 width를 기준으로 SEGMENT_WIDTH를 정하거나, 기존 SEGMENT_WIDTH를 이미지 폭에 맞게 조정한다.
- 각 세그먼트는 Sprite2D로 만든다.
- Sprite2D.centered = false
- Sprite2D.position.x = index * segment_width
- Sprite2D.position.y는 화면 하단 기준으로 레이어별 자연스럽게 배치한다.

권장 y 배치:
- FarLayer: 화면 높이의 약 0.42 ~ 0.50 지점
- MidLayer: 화면 높이의 약 0.48 ~ 0.58 지점
- NearLayer: 화면 높이의 약 0.68 ~ 0.78 지점

단, 실제 이미지 높이와 현재 게임 화면을 보고 자연스럽게 조정한다.

4. 기존 process_scroll 로직은 최대한 유지한다.
현재처럼 각 레이어 자식들을 run_speed * factor * delta 만큼 왼쪽으로 이동시키고, 화면 왼쪽 밖으로 나가면 오른쪽 끝으로 재배치한다.

다만 재배치 기준은 기존 도형 폭이 아니라 Sprite2D texture width 기준으로 처리한다.

예시 기준:
- child.position.x + sprite_width * child.scale.x < -buffer 이면
- 같은 레이어에서 가장 오른쪽에 있는 Sprite2D의 x 위치 + sprite_width * scale.x 로 이동

5. 이미지가 없거나 load 실패 시 게임이 바로 크래시되지 않도록 push_warning을 남기고 기존 임시 도형 fallback을 유지하거나, 최소한 빈 레이어로 넘어가도록 처리한다.

[GroundLooper.gd 수정]

1. 다음 이미지 경로를 상수로 선언한다.

const GROUND_TEXTURE_PATH := "res://assets/background/stage1/ground_tile_01.png"

2. 기존 GroundTile 도형 생성 로직을 제거하거나 비활성화하고, ground_tile_01.png를 사용하는 Sprite2D 타일 반복 구조로 교체한다.

3. GroundTile 개수는 화면 폭을 충분히 덮도록 계산하거나 기존 8개 구조를 유지해도 된다.
권장:
- texture_width를 기준으로 필요한 tile count 계산
- 최소 4개 이상
- 화면 폭 / tile_width + 2개 정도 여유분 생성

4. 각 ground sprite 설정:
- texture = load(GROUND_TEXTURE_PATH)
- centered = false
- position.x = index * tile_width
- position.y = 기존 바닥 y 위치에 맞춘다.
- 기존 플레이어가 서는 지면 높이와 충돌 기준은 바꾸지 않는다.
- 시각적 이미지만 교체한다.

5. 기존 GroundLooper의 이동 속도는 그대로 유지한다.
- 배경 패럴랙스가 아니라 실제 맵 속도와 동일하게 왼쪽으로 이동해야 한다.
- 화면 밖으로 나간 타일은 오른쪽 끝으로 재배치한다.

주의사항:
- 이미지 교체 작업 때문에 플레이어 위치, 점프/공격/충돌/장애물 스폰 위치가 바뀌면 안 된다.
- 지면의 시각적 y 위치와 실제 충돌 y 위치가 크게 어긋나면 안 된다.
- 배경 이미지가 화면을 가리거나 캐릭터보다 앞에 나오지 않도록 z_index를 정리한다.

권장 z_index:
- Sky: -100
- FarLayer: -80
- MidLayer: -60
- NearLayer: -40
- Ground visual: -20 또는 기존 바닥보다 뒤/아래
- Player / Enemy / Obstacle: 기존 값 유지
- UI: 기존 값 유지

검증 기준:
1. Godot 실행 시 에러 없이 러너 스테이지가 시작된다.
2. sky_static.png가 화면 전체 배경으로 표시된다.
3. far_mountains_01.png가 가장 느리게 스크롤된다.
4. mid_structures_01.png가 중간 속도로 스크롤된다.
5. near_foreground_01.png가 빠르게 스크롤된다.
6. ground_tile_01.png가 바닥으로 반복 스크롤된다.
7. 배경 루프 시 이미지가 순간적으로 사라지거나 큰 빈 공간이 생기지 않는다.
8. 플레이어 조작, 장애물, 충돌, 게임 속도 로직은 기존과 동일하게 동작한다.

작업 후 다음 내용을 보고하라:
- 수정한 파일 목록
- 각 레이어에 적용한 이미지 경로
- SEGMENT_WIDTH 또는 타일 폭을 어떤 기준으로 잡았는지
- 테스트 실행 결과
- 남아있는 시각적 문제나 추가 조정이 필요한 y 위치 / scale 값
