# Codex 작업 지시서: 사무라이 러닝 스프라이트 6프레임 생성 및 연속 재생

## 0. 입력 이미지 정의
이 작업에서 Codex 대화창에 첨부된 이미지를 다음처럼 해석한다.

- **ImageA**: Codex 대화창에 첨부한 첫 번째 이미지. 기존 서있는 사무라이 캐릭터 원본 이미지다.
- **ImageB**: Codex 대화창에 첨부한 두 번째 이미지. 몸을 앞으로 기울이고 달리기 시작하는 러닝 앵커 이미지다.
ImageA와 ImageB는 현재 본 md파일이 있는 위치에 함께있다. 이걸 참고하도록한다.

ImageA는 캐릭터 정체성 유지용이고, ImageB는 러닝 자세와 분위기 유지용이다.

## 1. 목표
ImageA와 ImageB를 기준으로, 모바일 2D 러너 게임에서 사용할 수 있는 **오른쪽을 향해 달리는 사무라이 러닝 루프 6프레임**을 만든다.

캐릭터는 칼을 뽑지 않는다. 칼은 칼집에 들어가 있어야 하며, 한 손은 항상 칼 손잡이를 잡고 있어야 한다. 상체는 낮고 앞으로 기울어진 발도 준비 자세를 유지하되, 다리는 명확하게 달리는 동작이어야 한다.

최종 산출물은 다음과 같다.

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

가능하다면 모든 프레임은 같은 캔버스 크기, 같은 캐릭터 크기, 같은 기준점으로 정렬한다.

## 2. 이미지 생성 도구 사용 규칙
Codex 환경에서 이미지 생성 도구를 사용할 수 있다면 아래 프롬프트를 순서대로 실행해 6장의 PNG를 생성한다.

이미지 생성 도구를 사용할 수 없다면, 이미지를 임의로 만들었다고 가정하지 말고 아래 6개 프롬프트를 별도 파일로 정리하고, 사용자가 외부 이미지 생성 도구에서 생성한 프레임 PNG를 `assets/sprites/samurai/run/` 폴더에 넣을 수 있도록 프로젝트 구조와 미리보기 재생 코드만 준비한다.

## 3. 참조 이미지 사용 방식
각 프레임 생성 시 기본적으로 다음 이미지를 참조한다.

- ImageA: 원본 캐릭터 정체성 유지용
- ImageB: 현재 잘 나온 러닝 앵커 자세 유지용

프레임별 생성 순서는 다음을 따른다.

1. `frame_01.png`: ImageA + ImageB를 참조해 생성한다.
2. `frame_02.png`: ImageA + ImageB + 직전에 생성된 `frame_01.png`를 참조해 생성한다.
3. `frame_03.png`: ImageA + ImageB + 직전에 생성된 `frame_02.png`를 참조해 생성한다.
4. `frame_04.png`: ImageA + ImageB + 직전에 생성된 `frame_03.png`를 참조해 생성한다.
5. `frame_05.png`: ImageA + ImageB + 직전에 생성된 `frame_04.png`를 참조해 생성한다.
6. `frame_06.png`: ImageA + ImageB + 직전에 생성된 `frame_05.png`를 참조해 생성한다.

단, 직전 프레임만 계속 참조해서 캐릭터 얼굴, 머리카락, 복장, 비율이 변형되기 시작하면 즉시 방식을 바꾼다. 그 경우에는 항상 ImageA와 ImageB를 우선 기준으로 두고, 직전 프레임은 동작 흐름 참고용으로만 약하게 사용한다.

## 4. 전체 공통 금지사항
아래 사항은 모든 프레임에 적용한다.

- 캐릭터를 새로 디자인하지 말 것.
- 얼굴, 표정, 머리색, 포니테일, 분홍색 기모노 상의, 검은 하카마, 샌들, 칼집 디자인을 바꾸지 말 것.
- 칼을 뽑지 말 것.
- 칼날을 노출하지 말 것.
- 일반 달리기처럼 팔을 크게 흔들지 말 것.
- 상체의 발도 준비 자세를 무너뜨리지 말 것.
- 정지 자세처럼 보이게 만들지 말 것.
- 배경, 바닥 그림자, 텍스트, 장식 오브젝트를 넣지 말 것.
- 캐릭터 방향을 바꾸지 말 것. 항상 오른쪽을 바라봐야 한다.

## 5. 공통 품질 기준
각 프레임은 다음 기준을 만족해야 한다.

- 한 장에 캐릭터 1명만 있어야 한다.
- 투명 배경 PNG여야 한다.
- 오른쪽을 향한 사이드뷰 또는 약한 3/4 사이드뷰여야 한다.
- 상체는 낮고 앞으로 기울어져야 한다.
- 한 손은 칼 손잡이를 잡고 있어야 한다.
- 다른 손은 칼집 근처 또는 몸 가까이에 있어야 한다.
- 다리 동작은 프레임마다 명확히 달라야 한다.
- 하카마 자락, 소매, 포니테일은 달리는 속도에 맞게 조금씩 펄럭여야 한다.
- 칼집과 허리 부분도 몸의 움직임에 따라 미세하게 흔들리는 느낌이 있어야 한다.
- 6장을 10~12 FPS로 반복 재생했을 때 자연스럽게 달리는 느낌이 나야 한다.

## 6. 프레임 생성 프롬프트
아래 프롬프트를 순서대로 사용한다.

---

## Prompt 1: frame_01.png

```text
Use the attached images as references.
ImageA is the original character identity reference.
ImageB is the running pose/style anchor reference.

Create a single 2D side-view running animation sprite of the same character for a mobile runner game.

Keep exactly the same:
- character identity
- face and expression
- chibi proportions
- pink ponytail hairstyle
- pink kimono top
- dark hakama
- sandals
- katana and scabbard
- right-facing direction
- transparent background
- same 2D sprite / game illustration style

Important action rules:
- This must be a clear running frame, not a standing pose and not just a ready stance.
- The sword remains sheathed.
- One hand grips the katana handle at all times.
- The other hand stays near the scabbard or close to the body for balance.
- The torso stays low and leans forward in an iai quick-draw running posture.
- The legs must show a strong, readable running stride.

This is frame 1 of a 6-frame running cycle.

Pose instructions:
- the front/right leg is extended forward and landing
- the back/left leg is stretched behind
- the body leans forward aggressively
- hips are low
- the ponytail trails slightly backward
- the hakama cloth opens slightly from the stride
- sleeves shift subtly with motion
- the scabbard and waist area show slight motion response
- this frame should clearly read as a landing step at speed

Important:
Do not redesign the character.
Do not turn this into a static stance.
This must read clearly as an active running animation frame.
Keep the upper body in a quick-draw-ready posture, but make the leg motion, cloth motion, sleeve motion, ponytail motion, and foot motion visibly dynamic.

Output:
- single full-body character only
- transparent background
- no scenery
- no text
- same scale and camera angle
- clean readable silhouette
- suitable as one frame of a looping 2D running cycle
```

---

## Prompt 2: frame_02.png

```text
Use the attached images as references.
ImageA is the original character identity reference.
ImageB is the running pose/style anchor reference.
If a previous generated frame is attached, use it only as the immediate motion continuity reference.

Create a single 2D side-view running animation sprite of the same character for a mobile runner game.

Keep exactly the same:
- character identity
- face and expression
- chibi proportions
- pink ponytail hairstyle
- pink kimono top
- dark hakama
- sandals
- katana and scabbard
- right-facing direction
- transparent background
- same 2D sprite / game illustration style

Important action rules:
- This must be a clear running frame, not a standing pose and not just a ready stance.
- The sword remains sheathed.
- One hand grips the katana handle at all times.
- The other hand stays near the scabbard or close to the body for balance.
- The torso stays low and leans forward in an iai quick-draw running posture.
- The legs must show a strong, readable running stride.

This is frame 2 of a 6-frame running cycle.

Pose instructions:
- the front/right leg is now taking weight and bending
- the back/left leg is beginning to recover forward
- the torso dips slightly lower from impact
- the ponytail swings with follow-through
- sleeves and hakama show subtle compression and motion
- the sandals and feet clearly show weight-bearing contact
- the scabbard angle shifts slightly with the body
- this frame should read as the weight-loading phase of a run

Important:
Do not redesign the character.
Do not turn this into a static stance.
This must read clearly as an active running animation frame.
Keep the upper body in a quick-draw-ready posture, but make the leg motion, cloth motion, sleeve motion, ponytail motion, and foot motion visibly dynamic.

Output:
- single full-body character only
- transparent background
- no scenery
- no text
- same scale and camera angle
- clean readable silhouette
- suitable as one frame of a looping 2D running cycle
```

---

## Prompt 3: frame_03.png

```text
Use the attached images as references.
ImageA is the original character identity reference.
ImageB is the running pose/style anchor reference.
If a previous generated frame is attached, use it only as the immediate motion continuity reference.

Create a single 2D side-view running animation sprite of the same character for a mobile runner game.

Keep exactly the same:
- character identity
- face and expression
- chibi proportions
- pink ponytail hairstyle
- pink kimono top
- dark hakama
- sandals
- katana and scabbard
- right-facing direction
- transparent background
- same 2D sprite / game illustration style

Important action rules:
- This must be a clear running frame, not a standing pose and not just a ready stance.
- The sword remains sheathed.
- One hand grips the katana handle at all times.
- The other hand stays near the scabbard or close to the body for balance.
- The torso stays low and leans forward in an iai quick-draw running posture.
- The legs must show a strong, readable running stride.

This is frame 3 of a 6-frame running cycle.

Pose instructions:
- the rear/left leg is pushing off strongly
- the front/right leg is moving back under the body
- the body drives forward with strong momentum
- the heel of the rear leg is lifted clearly
- the ponytail and cloth trail backward from acceleration
- the hakama flutters slightly more from the strong stride
- sleeves move subtly with the forward drive
- this frame should read as the propulsion / push-off phase

Important:
Do not redesign the character.
Do not turn this into a static stance.
This must read clearly as an active running animation frame.
Keep the upper body in a quick-draw-ready posture, but make the leg motion, cloth motion, sleeve motion, ponytail motion, and foot motion visibly dynamic.

Output:
- single full-body character only
- transparent background
- no scenery
- no text
- same scale and camera angle
- clean readable silhouette
- suitable as one frame of a looping 2D running cycle
```

---

## Prompt 4: frame_04.png

```text
Use the attached images as references.
ImageA is the original character identity reference.
ImageB is the running pose/style anchor reference.
If a previous generated frame is attached, use it only as the immediate motion continuity reference.

Create a single 2D side-view running animation sprite of the same character for a mobile runner game.

Keep exactly the same:
- character identity
- face and expression
- chibi proportions
- pink ponytail hairstyle
- pink kimono top
- dark hakama
- sandals
- katana and scabbard
- right-facing direction
- transparent background
- same 2D sprite / game illustration style

Important action rules:
- This must be a clear running frame, not a standing pose and not just a ready stance.
- The sword remains sheathed.
- One hand grips the katana handle at all times.
- The other hand stays near the scabbard or close to the body for balance.
- The torso stays low and leans forward in an iai quick-draw running posture.
- The legs must show a strong, readable running stride.

This is frame 4 of a 6-frame running cycle.

Pose instructions:
- both legs are transitioning under and past the body
- one leg swings forward while the other passes behind
- this is the airborne or near-airborne transition phase
- the torso remains low and controlled
- the ponytail swings with a slightly different angle than previous frames
- the hakama and sleeves show light flowing motion from speed
- the feet should read clearly as transitioning, not standing
- this frame should clearly read as a running transition

Important:
Do not redesign the character.
Do not turn this into a static stance.
This must read clearly as an active running animation frame.
Keep the upper body in a quick-draw-ready posture, but make the leg motion, cloth motion, sleeve motion, ponytail motion, and foot motion visibly dynamic.

Output:
- single full-body character only
- transparent background
- no scenery
- no text
- same scale and camera angle
- clean readable silhouette
- suitable as one frame of a looping 2D running cycle
```

---

## Prompt 5: frame_05.png

```text
Use the attached images as references.
ImageA is the original character identity reference.
ImageB is the running pose/style anchor reference.
If a previous generated frame is attached, use it only as the immediate motion continuity reference.

Create a single 2D side-view running animation sprite of the same character for a mobile runner game.

Keep exactly the same:
- character identity
- face and expression
- chibi proportions
- pink ponytail hairstyle
- pink kimono top
- dark hakama
- sandals
- katana and scabbard
- right-facing direction
- transparent background
- same 2D sprite / game illustration style

Important action rules:
- This must be a clear running frame, not a standing pose and not just a ready stance.
- The sword remains sheathed.
- One hand grips the katana handle at all times.
- The other hand stays near the scabbard or close to the body for balance.
- The torso stays low and leans forward in an iai quick-draw running posture.
- The legs must show a strong, readable running stride.

This is frame 5 of a 6-frame running cycle.

Pose instructions:
- the opposite leg from frame 1 now extends forward for landing
- the other leg stretches behind
- the posture mirrors the stride rhythm of frame 1
- the torso remains forward and low
- the ponytail and cloth continue to show directional motion
- the hakama opens slightly from the opposite stride
- sleeves shift naturally with movement
- this frame should clearly read as the second landing step

Important:
Do not redesign the character.
Do not turn this into a static stance.
This must read clearly as an active running animation frame.
Keep the upper body in a quick-draw-ready posture, but make the leg motion, cloth motion, sleeve motion, ponytail motion, and foot motion visibly dynamic.

Output:
- single full-body character only
- transparent background
- no scenery
- no text
- same scale and camera angle
- clean readable silhouette
- suitable as one frame of a looping 2D running cycle
```

---

## Prompt 6: frame_06.png

```text
Use the attached images as references.
ImageA is the original character identity reference.
ImageB is the running pose/style anchor reference.
If a previous generated frame is attached, use it only as the immediate motion continuity reference.

Create a single 2D side-view running animation sprite of the same character for a mobile runner game.

Keep exactly the same:
- character identity
- face and expression
- chibi proportions
- pink ponytail hairstyle
- pink kimono top
- dark hakama
- sandals
- katana and scabbard
- right-facing direction
- transparent background
- same 2D sprite / game illustration style

Important action rules:
- This must be a clear running frame, not a standing pose and not just a ready stance.
- The sword remains sheathed.
- One hand grips the katana handle at all times.
- The other hand stays near the scabbard or close to the body for balance.
- The torso stays low and leans forward in an iai quick-draw running posture.
- The legs must show a strong, readable running stride.

This is frame 6 of a 6-frame running cycle.

Pose instructions:
- the forward leg is now taking weight and slightly bent
- the rear leg is beginning to recover forward
- the torso dips slightly as in a compression phase
- the ponytail and hakama continue subtle motion
- sleeves and waist area show small follow-through movement
- the scabbard reacts slightly with the body
- this frame must connect smoothly back to frame 1
- the loop should feel natural and continuous

Important:
Do not redesign the character.
Do not turn this into a static stance.
This must read clearly as an active running animation frame.
Keep the upper body in a quick-draw-ready posture, but make the leg motion, cloth motion, sleeve motion, ponytail motion, and foot motion visibly dynamic.

Output:
- single full-body character only
- transparent background
- no scenery
- no text
- same scale and camera angle
- clean readable silhouette
- suitable as one frame of a looping 2D running cycle
```

## 7. 프레임 정리 및 후처리 지시
6장의 프레임이 모두 준비되면 다음 작업을 수행한다.

1. 모든 PNG를 `assets/sprites/samurai/run/`에 저장한다.
2. 파일명은 반드시 `frame_01.png`부터 `frame_06.png`까지 맞춘다.
3. 모든 이미지의 캔버스 크기를 동일하게 맞춘다.
4. 캐릭터 발 위치가 크게 흔들리지 않도록 기준점을 맞춘다.
5. 이미지가 투명 배경인지 확인한다.
6. 10~12 FPS 루프로 재생되는 미리보기를 만든다.
7. 가능하면 `run_preview.gif`를 생성한다. GIF 생성이 어렵다면 `run_preview.html`을 만들어 브라우저에서 반복 재생되게 한다.

## 8. manifest.json 예시

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

## 9. HTML 미리보기 요구사항
`run_preview.html`을 만들 경우 다음 조건을 만족한다.

- 6장의 이미지를 순서대로 반복 재생한다.
- 기본 FPS는 12로 한다.
- 배경은 투명 또는 체크보드 배경으로 표시한다.
- 재생/정지 버튼이 있으면 좋지만 필수는 아니다.
- 이미지 파일 경로는 `frame_01.png` ~ `frame_06.png`를 기준으로 한다.

## 10. 실패 판정 기준
아래 결과는 실패로 보고 재생성한다.

- 서있는 자세처럼 보인다.
- 다리 동작이 거의 변하지 않는다.
- 칼이 뽑혀 있다.
- 캐릭터가 왼쪽을 본다.
- 얼굴이나 머리 모양이 원본과 크게 달라졌다.
- 복장이 바뀌었다.
- 일반 질주 자세처럼 팔을 크게 흔들어 발도 준비 자세가 사라졌다.
- 배경이 생겼다.
- 프레임마다 캐릭터 크기가 크게 달라진다.

## 11. 최종 완료 조건
아래 조건을 모두 만족하면 완료로 본다.

- 6개 러닝 프레임 PNG가 존재한다.
- 모든 프레임이 오른쪽을 향한다.
- 모든 프레임에서 칼은 칼집에 들어가 있다.
- 한 손은 계속 칼 손잡이를 잡고 있다.
- 다리 동작, 하카마, 소매, 포니테일 움직임이 프레임마다 조금씩 다르다.
- 10~12 FPS로 반복 재생했을 때 실제로 달리는 느낌이 난다.
- `manifest.json`과 미리보기 파일이 함께 존재한다.
