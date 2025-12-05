# Score → 확률 변환 과정 상세 설명

## 전체 흐름 개요

```
y_score (raw score) 
  → sigmoid_fixed (QFRAC 확률: 0~64) 
  → prob_to_percent (퍼센트: 0~100%)
```

---

## 1단계: y_score 계산 (mlp_output_score.v)

### 입력
- `h_raw_bus`: Hidden layer의 raw score들 (ReLU 전)
- `w_o_bus`: 출력층 가중치들
- `b_o`: 출력층 bias

### 계산 과정
```verilog
// 1. ReLU 활성화
h_act[i] = (h_raw[i] > 0) ? h_raw[i] : 0

// 2. 출력층 계산
y_score = b_o + Σ(w_o[i] * scaled_h_act[i])
```

**스케일링 규칙:**
- `h_act[i] > 12`: 전체 가중치 적용 → `y_score += w_o[i]`
- `h_act[i] > 6`: 가중치의 3/4 적용 → `y_score += (w_o[i] * 3) >>> 2`
- `h_act[i] > 0`: 가중치의 1/2 적용 → `y_score += w_o[i] >>> 1`

### 출력
- `y_score`: signed [12:0] (13비트, -4096 ~ +4095 범위)
- 예시: `y_score = 628`, `820`, `852`, `1012`, `-128` 등

---

## 2단계: Sigmoid 근사 (sigmoid_fixed.v)

### 입력
- `z`: y_score (signed [12:0])

### Step 1: 스케일링
```verilog
x = z >>> SHIFT;  // SHIFT = 8
// Score를 256으로 나눔
```

**예시:**
- `y_score = 628` → `x = 628 >>> 8 = 2` (실제로는 2.45...)
- `y_score = 820` → `x = 820 >>> 8 = 3` (실제로는 3.20...)
- `y_score = 1012` → `x = 1012 >>> 8 = 3` (실제로는 3.95...)
- `y_score = -128` → `x = -128 >>> 8 = -1` (실제로는 -0.5)

### Step 2: Piecewise Linear Sigmoid 근사

**QFRAC 형식:**
- `FRAC = 6`이므로 `1.0 = 64` (2^6)
- `0.5 = 32` (2^5)
- `0.25 = 16` (2^4)

**구간별 계산:**

#### 음수 구간 (x < 0)
- **x <= -8**: `tmp = 0` (0%)
- **-8 < x <= -3**: 점진적으로 증가
- **-3 < x <= -2**: 작은 기울기
  ```verilog
  mult_tmp = (x + 3) * 2;
  tmp = 2*16 + (mult_tmp >>> 4) = 32 + ...
  ```
- **-2 < x <= -1**: 중간 기울기
  ```verilog
  mult_tmp = (x + 2) * 4;
  tmp = 4*16 + (mult_tmp >>> 3) = 64 + ...
  ```
- **-1 < x <= 0**: 큰 기울기 (0 근처에서 빠르게 변화)
  ```verilog
  mult_tmp = (x + 1) * 8;
  tmp = 16*16 + (mult_tmp >>> 2) = 256 + ...
  ```

#### 양수 구간 (x > 0)
- **0 < x <= 1**: 큰 기울기
  ```verilog
  mult_tmp = x * 8;
  tmp = 32*16 + (mult_tmp >>> 2) = 512 + ...
  ```
- **1 < x <= 2**: 중간 기울기
  ```verilog
  mult_tmp = (x - 1) * 4;
  tmp = 40*16 + (mult_tmp >>> 3) = 640 + ...
  ```
- **2 < x <= 3**: 작은 기울기
  ```verilog
  mult_tmp = (x - 2) * 2;
  tmp = 48*16 + (mult_tmp >>> 4) = 768 + ...
  ```
- **3 < x <= 4**: 세밀한 기울기 (Score=820, 852, 1012 구분)
  ```verilog
  if (x <= 3):
      tmp = 50*16 + ((x - 2) <<< 3) = 800 + ...
  else:
      mult_tmp = (x - 3) * 3;
      tmp = 52*16 + (mult_tmp >>> 2) = 832 + ...
  ```
- **4 < x <= 8**: 점진적으로 1.0에 접근
- **x >= 8**: `tmp = 64` (100%)

### Step 3: 클리핑
```verilog
if (tmp < 0) tmp = 0;
else if (tmp > 64) tmp = 64;  // 1.0 in QFRAC
```

### Step 4: 출력
```verilog
p_q = tmp[7:0];  // 하위 8비트만 사용 (0~64)
```

**예시:**
- `y_score = 628` → `x = 2` → `tmp ≈ 50*16 + ... = 800+` → `p_q ≈ 50` (QFRAC)
- `y_score = 820` → `x = 3` → `tmp ≈ 52*16 + ... = 832+` → `p_q ≈ 52` (QFRAC)
- `y_score = 1012` → `x = 3` → `tmp ≈ 52*16 + ... = 832+` → `p_q ≈ 52` (QFRAC)
- `y_score = -128` → `x = -1` → `tmp ≈ 16*16 + ... = 256+` → `p_q ≈ 16` (QFRAC)

---

## 3단계: 퍼센트 변환 (prob_to_percent.v)

### 입력
- `p_q`: QFRAC 확률 (0~64, 8비트)

### 계산 과정
```verilog
// 1. 100 곱하기
p_times100 = p_q * 100;

// 2. QFRAC 비트 제거 (>>> FRAC, FRAC=6)
percent = p_times100 >>> 6;
```

**수식:**
```
percent = (p_q * 100) / 64
        = p_q * 100 / 64
        = p_q * 1.5625
```

### 출력
- `percent`: 0~100 (7비트)

**예시:**
- `p_q = 50` (QFRAC) → `percent = (50 * 100) >>> 6 = 5000 >>> 6 = 78%`
- `p_q = 52` (QFRAC) → `percent = (52 * 100) >>> 6 = 5200 >>> 6 = 81%`
- `p_q = 16` (QFRAC) → `percent = (16 * 100) >>> 6 = 1600 >>> 6 = 25%`

---

## 전체 예시

### 예시 1: y_score = 820
1. **y_score 계산**: `820` (raw score)
2. **스케일링**: `x = 820 >>> 8 = 3`
3. **Sigmoid 근사**: 
   - `x = 3`이므로 `3 < x <= 4` 구간
   - `mult_tmp = (3 - 3) * 3 = 0`
   - `tmp = 52*16 + 0 = 832`
   - `p_q = 832[7:0] = 32` (실제로는 더 복잡한 계산)
4. **퍼센트 변환**: `percent = (32 * 100) >>> 6 = 50%`

### 예시 2: y_score = -128
1. **y_score 계산**: `-128` (raw score)
2. **스케일링**: `x = -128 >>> 8 = -1`
3. **Sigmoid 근사**:
   - `x = -1`이므로 `-2 < x <= -1` 구간
   - `mult_tmp = (-1 + 2) * 4 = 4`
   - `tmp = 4*16 + (4 >>> 3) = 64 + 0 = 64`
   - `p_q = 16` (QFRAC)
4. **퍼센트 변환**: `percent = (16 * 100) >>> 6 = 25%`

---

## 핵심 포인트

1. **QFRAC 형식**: `FRAC=6`이므로 `1.0 = 64`, `0.5 = 32`
2. **Piecewise Linear**: 실제 sigmoid 함수를 여러 선형 구간으로 근사
3. **구간별 기울기**: 0 근처에서 큰 기울기, 멀어질수록 작은 기울기
4. **다양성**: Score 값에 따라 다양한 확률 생성 (100%로 클리핑되지 않도록)

