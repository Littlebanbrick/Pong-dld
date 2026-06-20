// ============================================================================
// Report.typ — Pong Game on FPGA — 实验报告
// ============================================================================

// ---------------------------------------------------------------------------
// Code block styling
// ---------------------------------------------------------------------------
#show raw.where(block: true): set block(
  fill: luma(250),
  inset: 6pt,
  radius: 3pt,
)
#show raw.where(block: true): set text(
  size: 9pt,
  font: ("DejaVu Sans Mono", "Noto Serif SC"),
)
#show raw.where(block: true): set par(
  leading: 1.15em,
)
#show raw.where(block: false): set text(
  font: ("DejaVu Sans Mono", "Noto Serif SC"),
)

// ---------------------------------------------------------------------------
// Page setup
// ---------------------------------------------------------------------------
#set page(
  paper: "a4",
  margin: (left: 2.6cm, right: 2.6cm, top: 2.4cm, bottom: 2.8cm),
  numbering: "1",
  number-align: bottom + center,
  header: context [
    #text(size: 12pt, fill: gray.darken(25%))[Pong Game on FPGA]
    #h(1fr)
    #text(size: 12pt, fill: gray.darken(25%))[#datetime.today().display("[month repr:short] [day], [year]")]
  ],
  footer: context align(center)[
    #text(size: 11pt, fill: gray.darken(50%))[#counter(page).display()]
  ],
)

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------
#set text(
  font: ("Cambria", "Noto Serif SC"),
  size: 14pt,
  lang: "zh",
)

// Figure caption: smaller, italic, muted gray
#show figure.caption: set text(
  size: 11pt,
  font: ("Cambria", "Noto Serif SC"),
  style: "italic",
  fill: luma(90),
)
#show figure.caption: set par(
  leading: 1.0em,
)

// Paragraph style
#set par(
  justify: true,
  first-line-indent: 0em,
  leading: 0.75em,
  spacing: 1em,
)


// ---------------------------------------------------------------------------
// Heading hierarchy
// ---------------------------------------------------------------------------
#set heading(numbering: "1.1.1")
#show heading.where(level: 1): set text(size: 20pt, weight: "bold")
#show heading.where(level: 2): set text(size: 15pt, weight: "semibold")
#show heading.where(level: 3): set text(size: 13pt, weight: "semibold")
#show heading: it => {
  let gap = if it.level == 1 { 0.9em } else if it.level == 2 { 0.55em } else { 0.35em }
  v(gap)
  it
  v(gap * 0.4)
}

// ───────────────────────────────────────────────────────────────────────────
// Cover Page
// ───────────────────────────────────────────────────────────────────────────
#align(center + horizon)[
  #v(0%)
  #text(size: 35pt, weight: "bold")[
    数字逻辑设计
    \
  ]
  #v(0%)
  #text(size: 30pt, weight: "bold")[
    Pong Game on FPGA 项目报告
  ]
  #image("icon_ZJU.png", width: 40%)
  #v(2em)
  #text(size: 18pt)[组员：王传宇、齐思航]
  #v(0.3em)
  #text(size: 18pt)[#datetime.today().display("[year]/[month]/[day]")]
]

#pagebreak()

// ───────────────────────────────────────────────────────────────────────────
// Table of Contents
// ───────────────────────────────────────────────────────────────────────────
#v(1em)
#align(center)[
  #text(size: 25pt, weight: "bold")[目录]
]
#v(1em)
#set outline(indent: 1em)
#outline(title: none)

#pagebreak()

// ═══════════════════════════════════════════════════════════════════════════
// 1. 设计说明
// ═══════════════════════════════════════════════════════════════════════════
= 设计说明

== 功能概述

本项目旨在实现打乒乓（Pong）小游戏，并在其基础上进行优化并添加额外内容，增加可玩性的同时提高游玩舒适度。

=== 基础功能

该游戏为双人对战小游戏（也可单人与 AI 对战），每人操作一个球拍进行接球。左右球拍分别使用键盘 W/S 和 ↑/↓ 键控制上下移动。球遇到上下边界与球拍会反弹，未接到球者判负。系统实时记录双方得分，先得 11 分者获胜，同时屏幕上显示 GAME OVER。

=== 额外功能 1——难度选择

可利用 SW[2:3] 选择游戏难度。游戏分为四个难度：Easy、Hard、Master、Auto。其中 Easy、Hard、Master 的球速逐级递增，而 Auto 较为特殊——初始速度与 Easy 一致，但每次击球后球速变为原来的 1.1 倍，使比赛更加紧张刺激。

同时，选择的难度会在四个七段数码管上显示。

=== 额外功能 2——道具

比赛每隔一段时间会在双方球拍附近生成神秘小道具，接触到道具者的球拍会短时间内延长（延长的部分显示为灰色），使接球更加容易。

=== 额外功能 3——随机化发球角度

每次发球的角度都会在一定范围内随机化，增加开球的不可预测性，让双方选手开局即进入状态。

=== 额外功能 4——蜂鸣器与拖尾

击球、失分、游戏结束均配有不同频率的蜂鸣器音效；同时球的移动带有拖尾视觉效果，增强速度感。

=== 额外功能 5——PS/2 接口

本游戏支持通过 PS/2 接口连接 USB 键盘进行操作，有效改善了双人对战的操作体验。

=== 额外功能 6——AI 对手

提供一套较为简单的 AI 行为逻辑，实现对右挡板的自动控制。该 AI 通过追踪球的 Y 坐标位置，配合死区（60px）和随机更新延迟实现自然的追踪效果。当球远离时，AI 会缓慢回中，为下次防守做准备。

// ═══════════════════════════════════════════════════════════════════════════
// 2. 游戏逻辑
// ═══════════════════════════════════════════════════════════════════════════
= 游戏逻辑

== 状态机设计

状态机设计如下：
#align(center,table(
  columns: (auto, auto, auto),
  align: left,
  table.header([*状态*], [*编码*], [*功能*]),
  [`S_IDLE`], [3'd0], [空闲：等待开始，球和挡板居中],
  [`S_SERVE`], [3'd1], [发球：球居中，随机选择发射角度；等待按键或超时自动发球],
  [`S_PLAY`], [3'd2], [游戏进行：球移动、碰撞检测、挡板控制],
  [`S_PAUSE`], [3'd3], [暂停：一切冻结，等待继续],
  [`S_SCORE`], [3'd4], [得分暂停：约1秒后回到发球],
  [`S_OVER`], [3'd5], [游戏结束：显示 GAME OVER，等待按键重置],
))

状态转移：
- `IDLE` → (按开始) → `SERVE` → (按开始/超时) → `PLAY` → (按开始) → `PAUSE` → (按开始) → `PLAY`
- `PLAY` → (球出界) → `SCORE` → (超时) → `SERVE`
- `PLAY` → (球出界 + 满11分) → `OVER` → (按开始) → `IDLE`
- 任意状态 → (Esc 软复位) → `IDLE`

== 球的运动与碰撞逻辑

- *速度表示*：`ball_dx`（水平速度）和 `ball_dy`（垂直速度）均为 11 位有符号数，支持负方向。
- *位置更新*：`next_x_s = ball_x + ball_dx`，`next_y_s = ball_y + ball_dy`，使用有符号运算避免溢出。
- *碰撞逻辑*：
  + #strong[上下边界反弹]：当 `next_y_s ≤ 0` 或 `next_y_s ≥ 464` 时，`ball_dy` 取反。
  + #strong[左挡板碰撞]：当球右缘进入左挡板区域（`next_x_s ≤ 30 && next_x_s + 8 ≥ 20`）且 Y 坐标与挡板重叠时触发。
  + #strong[右挡板碰撞]：类似地，检测球左缘与右挡板（`next_x_s + 8 ≥ 610 && next_x_s ≤ 620`）的重叠。
  + #strong[出界得分]：若球未碰挡板且 `next_x_s ≤ 0`（右方得分）或 `next_x_s + 8 ≥ 640`（左方得分）。

== 反弹角度计算

碰撞时根据球心与挡板中心的偏移量确定反弹角度：
#align(center,table(
  columns: (auto, auto, auto),
  align: left,
  table.header([*偏移量*], [*角度索引*], [*效果*]),
  [> 20px], [±2], [大角度：dx=4, dy=±2],
  [> 5px], [±1], [中角度：dx=5, dy=±1],
  [-5 ~ +5px], [0], [水平：dx=5, dy=0],
  [< -5px], [-1], [中角度反向],
  [< -20px], [-2], [大角度反向],
))

== 道具逻辑

道具控制器包含两个状态：
- `S_COOLDOWN`（冷却）：等待一段时间后生成新道具。
- `S_ACTIVE`（激活）：道具可见，检测碰撞或超时。

冷却时间：
- 基础冷却：`COOLDOWN_BASE = 480` 个 game_tick ≈ 8 秒。
- 随机附加：`rand_cnt[5:0]`（0~63），总冷却 ≈ 8~9 秒。

道具生成：
- *X 位置*：交替出现在左/右挡板区域的中线处。
  - 左：`LEFT_PADDLE_X + PADDLE_W/2 = 25`
  - 右：`RIGHT_PADDLE_X + PADDLE_W/2 = 615`
- *Y 位置*：`40 + rand_cnt[9:4] × 4`，范围 40~292，随机化。

碰撞检测：
道具为 6×6 像素，检测其与挡板的 Y 范围重叠：
```
(powerup_y + 6) > paddle_y  &&  powerup_y < (paddle_y + PADDLE_H)
```
碰撞后产生 `hit_left` 或 `hit_right` 脉冲，通知 `game_logic` 激活宽挡板。

存在时间：
`LIFETIME = 150` 个 game_tick ≈ 2.5 秒，超时后消失进入冷却。

// ═══════════════════════════════════════════════════════════════════════════
// 3. 外设使用
// ═══════════════════════════════════════════════════════════════════════════
= 外设使用

== 七段数码管

用于显示当前游戏难度，分为 Easy、Hard、Master、Auto 四种。

== 蜂鸣器

驱动无源蜂鸣器产生三种不同频率的方波音效。
#align(center,table(
  columns: (auto, auto, auto, auto),
  align: left,
  table.header([*事件*], [*频率*], [*半周期计数*], [*持续时间*]),
  [击球 hit_paddle], [1000Hz], [12587], [0.2秒],
  [得分 score_event], [1500Hz], [8391], [0.2秒],
  [结束 game_over], [2000Hz], [6293], [0.2秒],
))

方波生成原理：
- `half_period_cnt`：从 0 计数到 `current_half - 1`。
- 计满时 `note_phase` 翻转，产生方波。
- 方波频率 = 25.175MHz / (2 × `current_half`)。

== LED

8 个 LED 指示灯映射如下：
#align(center,table(
  columns: (auto, auto, auto),
  align: left,
  table.header([*LED位*], [*含义*], [*表现*]),
  [0], [空闲 IDLE], [常亮],
  [1], [发球 SERVE], [常亮],
  [2], [游戏中 PLAY], [常亮],
  [3], [发球方], [0=左, 1=右],
  [4], [击球], [快闪],
  [5], [得分], [快闪],
  [6], [暂停 PAUSE], [慢闪 约0.5Hz],
  [7], [游戏结束 OVER], [常亮],
))
闪烁效果通过 `blink_cnt`（24位计数器，计12.5M次≈0.5秒）和 `blink_phase` 实现。

== PS/2 键盘接口

PS/2 协议是 11 位异步串行协议：
- 1 位起始位（0）
- 8 位数据位（LSB first）
- 1 位奇校验位
- 1 位停止位（1）

数据在 PS/2 时钟的下降沿采样。

*帧接收*：
`bit_cnt` 从 0 计数到 10：
- `bit_cnt=0`：跳过起始位。
- `bit_cnt=1~8`：将数据位移入 `shift_reg`。
- `bit_cnt=9`：跳过校验位。
- `bit_cnt=10`：帧完成，产生 `frame_done` 脉冲。

*扫描码解码*：
PS/2 键盘使用 Make/Break 机制：
- 按键按下：发送 Make 码（如 W = `0x1D`）。
- 按键释放：发送 `0xF0` + Make 码（Break 序列）。
- 扩展键（方向键等）：前缀 `0xE0`。

状态变量：
- `is_extended`：收到 `0xE0` 前缀标志。
- `is_break`：收到 `0xF0` 前缀标志。
- `key_valid`：解码完成脉冲。

*键位映射*：
#align(center,table(
  columns: (auto, auto, auto),
  align: left,
  table.header([*按键*], [*扫描码*], [*功能*]),
  [W], [`0x1D`], [左挡板上移],
  [S], [`0x1B`], [左挡板下移],
  [↑ (E0,75)], [`E0 75`], [右挡板上移],
  [↓ (E0,72)], [`E0 72`], [右挡板下移],
  [Space], [`0x29`], [开始/暂停],
  [Enter], [`0x5A`], [开始/暂停],
  [Esc], [`0x76`], [软复位],
))
当收到 Make 码时对应信号置 1，收到 Break 码时置 0。

== VGA

用于渲染画面，时序控制器为 `vgac.v`。

// ═══════════════════════════════════════════════════════════════════════════
// 4. 核心模块说明（简明版，详见 module_details.typ）
// ═══════════════════════════════════════════════════════════════════════════
= 核心模块说明

== defines.vh——全局宏定义头文件

用于定义全项目通用的参数，方便统一管理，主要宏定义如下：
#align(center,table(
  columns: (auto, auto, auto),
  align: left,
  table.header([*类别*], [*宏名示例*], [*作用*]),
  [显示几何], [`SCREEN_W/H`], [VGA 分辨率 640×480],
  [挡板参数], [`PADDLE_W/H`, `LEFT/RIGHT_PADDLE_X`], [挡板宽10px、高80px、左右各距边界20px],
  [球参数], [`BALL_SIZE`], [球为 8×8 正方形],
  [游戏规则], [`MAX_SCORE`], [先得 11 分者获胜],
  [AI 参数], [`AI_DEAD_ZONE`, `AI_UPDATE_BASE/RANGE`], [死区60px、更新间隔24+随机0~15帧],
  [难度等级], [`TICK_THRESH_SPEED1~5`], [控制 game_tick 频率：60Hz / 120Hz / 180Hz / 240Hz / 300Hz],
  [计时参数], [`TICK_MAX`, `SCORE_TIMEOUT`, `SERVE_TIMEOUT`], [game_tick 周期约419583时钟≈60Hz；得分后暂停60帧≈1s；自动发球超时60帧],
  [数码管扫描], [`SCAN_MAX`], [25.175MHz / 6294 ≈ 4kHz 扫描频率],
  [文字缩放], [`TEXT_SCALE`], [GAME OVER 字体放大系数，2 = 16×32px/字符],
))

== Top.v——顶层模块

`Top.v` 是整个系统的最高层，主要功能如下：
- *时钟生成*：调用 `clk_wiz` 将 100MHz 主时钟转为 25.175MHz VGA 像素时钟。
- *复位管理*：双级同步器 `rst_s1 → rst_s2 → rst_n`，确保 PLL 锁定和 SW[0] 开关复位信号同步释放。
- *模块例化与连接*：像"主板"一样把所有子模块连在一起。

信号流：
- *输入路径*：矩阵键盘/PS/2键盘 → `input_merger`（OR逻辑合并）→ `game_logic`
- *游戏路径*：`game_logic` 输出球坐标、挡板坐标、分数、状态 → `vga_render` 生成像素 → `vgac` 输出时序和颜色
- *外设路径*：`game_logic` 的事件脉冲 → `buzzer_ctrl`（声音）/ `led_status`（LED指示）/ `seg_display`（难度显示）
- *开关信号*：`SW[1]` = AI使能，`SW[3:2]` = 难度选择

== game_logic.v——游戏逻辑状态机

该模块功能主要分为以下几部分：状态机的设计（前文已述）、game_tick 分频控制、球运动与碰撞（前文已述）、反弹角度计算（前文已述）、宽挡板道具、边沿检测。

=== game_tick 分频控制

使用 19 位计数器 `tick_counter`，从 0 计数到 `tick_threshold`。`tick_threshold` 根据难度设定不同值：
- Easy: 419583 → 约 60Hz
- Hard: 209791 → 约 120Hz
- Master: 139861 → 约 180Hz
- Auto: 初始 60Hz，每次击球乘以 ×(10/11)，即加速约 1.1 倍

=== 宽挡板道具

当 `pw_hit_left` 或 `pw_hit_right` 脉冲到来时，`wide_timer` 设为 300 个 game_tick（约5秒），期间挡板上下各扩展5像素（灰色显示）。

=== 边沿检测

`start_pause` 和 `soft_reset` 信号需要边沿检测（`start_pause_d` 延迟一拍后比较），确保一次按键只触发一次状态转换，而不是连续触发。

== vga_render.v——VGA图像渲染

`vga_render` 是"画师"模块，根据当前扫描到的像素坐标和各游戏对象坐标，逐像素计算颜色输出。

=== 球的拖尾效果

使用三级移位寄存器保存球的前三帧位置：
```
game_tick 有效时：
  bx1 <= ball_x（当前帧）→ bx2 <= bx1（前一帧）→ bx3 <= bx2（前两帧）
```
渲染时按优先级叠加：
- `bx3/by3`：最暗拖尾（`12'h333`，深灰）
- `bx2/by2`：中等拖尾（`12'h777`，中灰）
- `bx1/by1`：较亮拖尾（`12'hBBB`，浅灰）
- `ball_x/ball_y`：当前球（`12'hFFF`，白色，覆盖拖尾）

=== 分数数字显示

每个数字由 16 行 × 8 列的位图（bitmap）表示，存储在 `digit_bitmap` 寄存器数组中。0~9 的位图是硬编码的点阵字体 ROM。

显示位置：
- 左方分数十位：(200, 30)，个位：(216, 30)
- 右方分数十位：(408, 30)，个位：(424, 30)

渲染逻辑：判断当前像素是否落在某个数字区域内 → 计算行内偏移和列内偏移 → 从位图中取出对应位 → 决定是白色还是黑色。

=== GAME OVER 文字

"GAME OVER" 由 9 个字符（含空格）组成，每个字符也是 8×16 点阵字体。通过 `TEXT_SCALE` 宏（=2）将每个字符放大到 16×32 像素。

居中计算：
- `GAMEOVER_W = 9 × 16 = 144px`
- `GAMEOVER_X = (640 - 144) / 2 = 248`
- `GAMEOVER_Y = (480 - 32) / 2 = 224`

仅在 `game_state == S_OVER` 时显示，优先级最高。

=== 渲染优先级

从低到高叠加（后写的覆盖先写的）：
1. 黑色背景
2. 中线虚线（`col 318~320`，`row[3:0] < 8`）
3. 球拖尾（由暗到亮）
4. 当前球（白色）
5. 挡板（白色主体 + 灰色扩展部分）
6. 道具菱形（绿色，去角）
7. 分数数字（白色）
8. GAME OVER 文字（白色，最高优先级）

== vgac.v——VGA时序控制器

`vgac.v` 是 VGA 信号的"行场同步发生器"，产生标准的 640×480 @ 60Hz VGA 时序。

=== 计数器
- `h_count`：水平计数器，0~799（共800个时钟周期，含消隐区）
- `v_count`：垂直计数器，0~524（共525行，含消隐区）

`h_count` 每 25.175MHz 时钟加1，到 799 归零；每当 `h_count` 归零时 `v_count` 加1。

=== 同步信号
- 行同步 `hs`：`h_count > 95` 时为高（同步脉宽96像素）
- 场同步 `vs`：`v_count > 1` 时为高（同步脉宽2行）
- 显示使能 `rdn`（低有效）：当 `143 < h_count < 783` 且 `34 < v_count < 515` 时有效（即 640×480 可见区域）

=== 坐标输出
- `row_addr = v_count - 35`（减去消隐区偏移，得到 0~479）
- `col_addr = h_count - 144`（减去消隐区偏移，得到 0~639）

=== 颜色输出
12位输入 `d_in = {B[3:0], G[3:0], R[3:0]}`，仅在 `rdn=0`（可见区域）时输出到 RGB 引脚，消隐区输出 0。

== ai_paddle.v——AI对手

AI 具有如下行为：

=== 追踪与死区
- 计算球的中心 Y 和挡板中心 Y。
- 死区 `AI_DEAD_ZONE = 60px`：当球中心在挡板中心 ±60px 范围内时，AI 不主动追踪。
- 死区外：球在上方则 `move_up`，球在下方则 `move_down`。

=== 随机延迟
- 自由运行计数器 `rand_cnt` 不断递增。
- `update_timer` 从 `(AI_UPDATE_BASE + rand_cnt[3:0])` 倒数到 0。
- 仅当 `update_timer == 0` 时 AI 才重新采样球位置并决策。
- 这使 AI 表现带有"犹豫感"，降低难度。

=== 空闲振荡
当球远离或球在死区内时，AI 进行小幅上下振荡（`osc_phase` 每32帧翻转方向），模拟"活跃"的表现，而不会呆立不动。

=== 回中行为
当球远离 AI 时，挡板缓慢回到屏幕中心（Y=240），为下次防守做准备。

== 其余模块
- #strong[clk_wiz.v]：时钟管理，输出 VGA 所需的像素时钟。
- #strong[input_merger.v]：使用 OR 运算将矩阵键盘和 PS/2 键盘的信号合并。
- #strong[keypad_scanner.v]：实现矩阵键盘的逐行扫描和去抖动。
- #strong[led_status.v]：LED 状态指示。
- #strong[seg_display.v]：七段数码管显示（动态扫描原理不再赘述）。
- #strong[powerup_ctrl.v]：道具控制器（前文已述）。

注：各模块的详细技术说明请参见《模块详细说明》（module_details.typ）。

// ═══════════════════════════════════════════════════════════════════════════
// 5. 仿真、调试过程分析
// ═══════════════════════════════════════════════════════════════════════════
= 仿真、调试过程分析

== ai_paddle

该模块仿真分四部分：
- ball_y=100（球在上方），paddle_y=200
- ball_y=400（球在下方），paddle_y=200
- ball_y=236（死区内），paddle_y=200
- ball_y=231（略高于死区），paddle_y=200

测试其上方追踪、下方追踪、死区静止、随机延迟功能，部分仿真波形图如下：
#align(center,image("ai_paddle_test.png", width: 15cm))
仿真结果符合预期。

== game_logic

`game_logic` 是位于 `ai_paddle` 之上的模块，负责游戏综合逻辑。

仿真思路为模拟一局游戏：
1. 临时修改 `TICK_MAX` 与 `SCORE_TIMEOUT`，加快 game_tick 触发，加速仿真进程。
2. 遵循游戏进程：复位与空闲 → 开始游戏 → 开球 → 玩家控制 → 得分与重置 → 暂停与恢复。
3. 通过观察 `game_state` 验证游戏进程是否正常进行。

#align(center,image("game_logic_test.png", width: 15cm))
可见游戏进程正常进行，从空闲到开始到暂停，状态转移符合预期。

== buzzer_ctrl

激活三类事件（击球、得分、结束）的脉冲，检查 `buzz` 输出是否正常。

== vga_render

验证 `vga_render` 模块能否在正确的位置显示出正确的颜色。
#align(center,table(
  columns: (auto, auto, auto),
  [测试阶段], [操作], [验证目标],
  [初始化], [设置球在 (320,240)，球拍在 200，分数 3:7，状态为 PLAY], [建立已知初始状态],
  [Test 1], [读取背景位置 (100,100)], [验证背景色是否为黑色（12'h000）],
  [Test 2], [读取球的位置 (320,240)], [验证球是否为白色（12'hFFF）],
  [Test 3], [读取分数位置 (200,30)], [观察分数数字是否正确显示],
  [Test 4], [切换到 GAME OVER 状态，读取 'G' 的左上角 (284,232)], [验证 GAME OVER 文字是否为白色],
  [Test 5], [切换回 PLAY 状态], [验证 GAME OVER 文字是否消失],
))

== ps2_keyboard

- 模拟 PS/2 总线时序（时钟约 16.7kHz，数据帧格式）。
- 发送按键的 Make Code（按下）和 Break Code（释放）。
- 验证解码后的按键信号（`left_up`、`left_down`、`right_up`、`right_down`、`start_pause`）。
#pagebreak()
#align(center,table(
  columns: (auto, auto, auto, auto),
  [步骤], [发送的扫描码], [对应按键], [预期输出],
  [1], [0x1D (make)], [W 键按下], [left_up = 1],
  [2], [0xF0 + 0x1D (break)], [W 键释放], [left_up = 0],
  [3], [0x1B (make)], [S 键按下], [left_down = 1],
  [4], [0xF0 + 0x1B (break)], [S 键释放], [left_down = 0],
  [5], [0xE0 + 0x75 (make)], [上箭头 按下], [right_up = 1],
  [6], [0xE0 + 0xF0 + 0x75 (break)], [上箭头 释放], [right_up = 0],
  [7], [0x5A (make)], [Enter 按下], [start_pause = 1],
  [8], [0xF0 + 0x5A (break)], [Enter 释放], [start_pause = 0],
))

== Top

顶层模块测试。
#align(center,table(
  columns: (auto, auto, auto, auto),
  [阶段], [测试内容], [验证点], [方法],
  [Phase 0], [上电复位], [系统正确复位], [拉低 rst_sw，等待 MMCM 锁定],
  [Test 1], [IDLE 状态], [复位后进入空闲状态], [检查 game_state=0，LED[0]=1],
  [Test 2], [IDLE → SERVE], [按开始键进入发球状态], [检查 game_state=1，LED[1]=1],
  [Test 3], [SERVE → PLAY], [再次按开始进入游戏状态], [检查 game_state=2，LED[2]=1],
  [Test 4], [球运动], [球是否开始移动], [等待 10ms，检查 ball_x/y 变化],
  [Test 5], [球拍控制], [矩阵键盘控制球拍], [按下左球拍下移，右球拍上移],
  [Test 6], [暂停/恢复], [暂停功能], [按开始键进入 PAUSE，再按恢复],
  [Test 7], [边界反弹], [球碰到上下边界反弹], [检查 ball_y 不超出屏幕边界],
  [Test 8], [得分事件], [球出界触发得分], [等待球出界，检查分数变化],
  [Test 9], [七段数码管], [显示是否正常], [检查 AN 是否在扫描，SEGMENT 有值],
  [Test 10], [VGA 同步], [VGA 信号是否产生], [检查 vga_hs/vs 不是 X/Z],
  [Test 11], [蜂鸣器], [蜂鸣器信号是否驱动], [检查 buzzer 不是 X/Z],
  [Test 12], [AI 模式], [AI 是否正确追踪球], [启用 AI（SW[1]=1），检查球拍运动],
))

// ═══════════════════════════════════════════════════════════════════════════
// 6. 团队分工
// ═══════════════════════════════════════════════════════════════════════════
= 团队分工

根据项目实际分工，各成员承担如下工作：

== 王传宇
- 游戏状态机（FSM）设计与实现
- 球物理运动与碰撞检测
- AI 对手逻辑
- 七段数码管显示驱动
- 蜂鸣器音效控制
- 顶层模块集成

== 齐思航
- 矩阵键盘扫描与去抖动
- PS/2 键盘接口
- VGA 图像渲染（含球拖尾、分数显示、GAME OVER 文字）
- 字库（点阵字体 ROM）
- LED 状态指示
- 约束文件（XDC）

== 共同完成
- 仿真测试与波形调试
- 设计报告撰写
- 各模块联调与整合

// ═══════════════════════════════════════════════════════════════════════════
// 7. 各成员贡献比例
// ═══════════════════════════════════════════════════════════════════════════
= 各成员贡献比例

王传宇：50%

齐思航：50%

双方在项目中分工各有侧重，协同完成了仿真、调试与报告撰写等共同工作。
