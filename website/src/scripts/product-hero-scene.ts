import {
  ACESFilmicToneMapping,
  BufferAttribute,
  CanvasTexture,
  CircleGeometry,
  Clock,
  CurvePath,
  CylinderGeometry,
  FogExp2,
  Group,
  HemisphereLight,
  LineCurve3,
  LinearFilter,
  LinearMipmapLinearFilter,
  MathUtils,
  Mesh,
  MeshBasicMaterial,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  Object3D,
  PCFSoftShadowMap,
  PerspectiveCamera,
  PlaneGeometry,
  PointLight,
  QuadraticBezierCurve3,
  Raycaster,
  Scene,
  Shape,
  ShapeGeometry,
  SpotLight,
  SRGBColorSpace,
  TubeGeometry,
  Vector2,
  Vector3,
  WebGLRenderer,
} from 'three';
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';

type TaskPreview = {
  title: string;
  tag: string;
  time: string;
};

type ProductSceneCopy = {
  remaining: string;
  search: string;
  newTodo: string;
  today: string;
  tasks: [TaskPreview, TaskPreview, TaskPreview];
  boardTitle: string;
  boardCount: string;
  drawerTitle: string;
  titleLabel: string;
  titleValue: string;
  contentLabel: string;
  contentValue: string;
  save: string;
};

type Disposable = {
  dispose: () => void;
};

type ScenePanel = {
  group: Group;
  body: Mesh<RoundedBoxGeometry, MeshPhysicalMaterial>;
};

const SELECTORS = {
  stage: '[data-product-scene]',
  canvas: '[data-product-scene-canvas]',
} as const;

const COLORS = {
  accent: '#2dd4c7',
  accentBright: '#6af2e5',
  ink: '#031c1a',
  panel: '#1b2d30',
  panelRaised: '#263a3e',
  panelDark: '#0d181a',
  text: '#f3f8f7',
  textSoft: '#d4dfdd',
  textMuted: '#9aaba9',
  line: 'rgba(202, 229, 226, 0.22)',
  blue: '#5b8ff9',
  purple: '#8a72eb',
  orange: '#ff8550',
  board: '#48528a',
} as const;

const TEXTURE_PIXEL_RATIO = 1.5;
const TEXTURE_ANISOTROPY = 16;
const PANEL_FACE_INSET = 0.018;
const PANEL_FACE_DEPTH_OFFSET = 0.004;
const PANEL_FACE_CURVE_SEGMENTS = 16;
const DESKTOP_RENDER_PIXEL_RATIO = 2;
const COMPACT_RENDER_PIXEL_RATIO = 1.35;
const CONVEYOR_RAIL_RADIUS = 0.105;
const CONVEYOR_CARRIER_DEPTH = 0.16;
const CONVEYOR_CARRIER_GAP = 0.045;
const CONVEYOR_CARRIER_Z_OFFSET =
  CONVEYOR_RAIL_RADIUS + CONVEYOR_CARRIER_DEPTH / 2 + CONVEYOR_CARRIER_GAP;
const PRODUCT_FRAME = {
  width: 17.08,
  height: 9.04,
  depth: 0.38,
  cornerRadius: 0.48,
  innerInset: 0.3,
  innerDepth: 0.16,
  innerCornerRadius: 0.42,
  trackInset: 0.11,
  trackZ: -0.91,
} as const;

const DEFAULT_COPY: ProductSceneCopy = {
  remaining: '3 tasks remaining',
  search: 'Search todos',
  newTodo: 'New',
  today: 'Today',
  tasks: [
    { title: 'Plan a focused morning', tag: 'Personal', time: '09:10' },
    { title: 'Review the launch checklist', tag: 'Work', time: '11:30' },
    { title: 'Write down one good idea', tag: 'Ideas', time: '16:20' },
  ],
  boardTitle: 'This week',
  boardCount: '3 todos',
  drawerTitle: 'New todo',
  titleLabel: 'Title',
  titleValue: 'Prepare tomorrow’s top task',
  contentLabel: 'Content',
  contentValue: 'Add a short note so the next step is clear.',
  save: 'Add todo',
};

const mountedStages = new WeakSet<HTMLElement>();

const PANEL_LAYOUT = {
  main: new Vector3(-0.38, -0.06, 0.48),
  boardCollapsed: new Vector3(-1.68, -2.62, -0.12),
  boardExpanded: new Vector3(-4.8, -1.72, 1.16),
  drawerCollapsed: new Vector3(0.9, 0.98, -0.28),
  drawerExpanded: new Vector3(4.8, 0.7, 1.02),
} as const;

const COIN_BASE_POSITION = new Vector3(3.52, -3.22, 2.16);

function dataValue(stage: HTMLElement, key: keyof DOMStringMap, fallback: string) {
  const value = stage.dataset[key];
  return value?.trim() || fallback;
}

function readSceneCopy(stage: HTMLElement): ProductSceneCopy {
  return {
    remaining: dataValue(stage, 'remaining', DEFAULT_COPY.remaining),
    search: dataValue(stage, 'search', DEFAULT_COPY.search),
    newTodo: dataValue(stage, 'newTodo', DEFAULT_COPY.newTodo),
    today: dataValue(stage, 'today', DEFAULT_COPY.today),
    tasks: [
      {
        title: dataValue(
          stage,
          'taskOneTitle',
          DEFAULT_COPY.tasks[0].title,
        ),
        tag: dataValue(stage, 'taskOneTag', DEFAULT_COPY.tasks[0].tag),
        time: dataValue(stage, 'taskOneTime', DEFAULT_COPY.tasks[0].time),
      },
      {
        title: dataValue(
          stage,
          'taskTwoTitle',
          DEFAULT_COPY.tasks[1].title,
        ),
        tag: dataValue(stage, 'taskTwoTag', DEFAULT_COPY.tasks[1].tag),
        time: dataValue(stage, 'taskTwoTime', DEFAULT_COPY.tasks[1].time),
      },
      {
        title: dataValue(
          stage,
          'taskThreeTitle',
          DEFAULT_COPY.tasks[2].title,
        ),
        tag: dataValue(stage, 'taskThreeTag', DEFAULT_COPY.tasks[2].tag),
        time: dataValue(stage, 'taskThreeTime', DEFAULT_COPY.tasks[2].time),
      },
    ],
    boardTitle: dataValue(stage, 'boardTitle', DEFAULT_COPY.boardTitle),
    boardCount: dataValue(stage, 'boardCount', DEFAULT_COPY.boardCount),
    drawerTitle: dataValue(stage, 'drawerTitle', DEFAULT_COPY.drawerTitle),
    titleLabel: dataValue(stage, 'titleLabel', DEFAULT_COPY.titleLabel),
    titleValue: dataValue(stage, 'titleValue', DEFAULT_COPY.titleValue),
    contentLabel: dataValue(stage, 'contentLabel', DEFAULT_COPY.contentLabel),
    contentValue: dataValue(stage, 'contentValue', DEFAULT_COPY.contentValue),
    save: dataValue(stage, 'save', DEFAULT_COPY.save),
  };
}

function roundedRect(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  width: number,
  height: number,
  radius: number,
  fill: string,
  stroke?: string,
) {
  context.beginPath();
  context.roundRect(x, y, width, height, radius);
  context.fillStyle = fill;
  context.fill();
  if (!stroke) return;
  context.strokeStyle = stroke;
  context.lineWidth = 2;
  context.stroke();
}

function drawCheckmark(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  size: number,
  color: string,
) {
  context.beginPath();
  context.moveTo(x, y + size * 0.54);
  context.lineTo(x + size * 0.34, y + size * 0.86);
  context.lineTo(x + size, y);
  context.strokeStyle = color;
  context.lineCap = 'round';
  context.lineJoin = 'round';
  context.lineWidth = Math.max(4, size * 0.18);
  context.stroke();
}

function drawCenteredCheckmark(
  context: CanvasRenderingContext2D,
  centerX: number,
  centerY: number,
  size: number,
  color: string,
) {
  drawCheckmark(
    context,
    centerX - size / 2,
    centerY - size * 0.43,
    size,
    color,
  );
}

function drawPlusIcon(
  context: CanvasRenderingContext2D,
  centerX: number,
  centerY: number,
  size: number,
  color: string,
) {
  const half = size / 2;
  context.save();
  context.strokeStyle = color;
  context.lineWidth = Math.max(3, size * 0.16);
  context.lineCap = 'round';
  context.beginPath();
  context.moveTo(centerX - half, centerY);
  context.lineTo(centerX + half, centerY);
  context.moveTo(centerX, centerY - half);
  context.lineTo(centerX, centerY + half);
  context.stroke();
  context.restore();
}

function drawCloseIcon(
  context: CanvasRenderingContext2D,
  centerX: number,
  centerY: number,
  size: number,
  color: string,
) {
  const half = size / 2;
  context.save();
  context.strokeStyle = color;
  context.lineWidth = Math.max(3, size * 0.16);
  context.lineCap = 'round';
  context.beginPath();
  context.moveTo(centerX - half, centerY - half);
  context.lineTo(centerX + half, centerY + half);
  context.moveTo(centerX + half, centerY - half);
  context.lineTo(centerX - half, centerY + half);
  context.stroke();
  context.restore();
}

function drawCenteredIconLabel(
  context: CanvasRenderingContext2D,
  label: string,
  centerX: number,
  centerY: number,
  iconSize: number,
  gap: number,
  color: string,
  drawIcon: (
    context: CanvasRenderingContext2D,
    centerX: number,
    centerY: number,
    size: number,
    color: string,
  ) => void,
) {
  const labelWidth = context.measureText(label).width;
  const contentWidth = iconSize + gap + labelWidth;
  const contentStart = centerX - contentWidth / 2;

  drawIcon(
    context,
    contentStart + iconSize / 2,
    centerY,
    iconSize,
    color,
  );

  context.save();
  context.fillStyle = color;
  context.textAlign = 'left';
  context.textBaseline = 'middle';
  context.fillText(label, contentStart + iconSize + gap, centerY + 1);
  context.restore();
}

function drawSearchIcon(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  radius: number,
) {
  context.beginPath();
  context.arc(x, y, radius, 0, Math.PI * 2);
  context.strokeStyle = COLORS.textSoft;
  context.lineWidth = 5;
  context.stroke();
  context.beginPath();
  context.moveTo(x + radius * 0.72, y + radius * 0.72);
  context.lineTo(x + radius * 1.55, y + radius * 1.55);
  context.stroke();
}

function drawArchiveIcon(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  size: number,
) {
  const half = size / 2;
  context.save();
  context.translate(x, y);
  context.strokeStyle = COLORS.textSoft;
  context.lineWidth = 4;
  context.lineCap = 'round';
  context.lineJoin = 'round';
  roundedRect(
    context,
    -half,
    -half + 5,
    size,
    size - 8,
    3,
    'transparent',
    COLORS.textSoft,
  );
  context.beginPath();
  context.moveTo(-half - 2, -half + 5);
  context.lineTo(half + 2, -half + 5);
  context.moveTo(0, -7);
  context.lineTo(0, 7);
  context.moveTo(-6, 1);
  context.lineTo(0, 7);
  context.lineTo(6, 1);
  context.stroke();
  context.restore();
}

function drawStickyBoardIcon(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  size: number,
) {
  const half = size / 2;
  const fold = size * 0.28;
  context.save();
  context.translate(x, y);
  context.strokeStyle = COLORS.textSoft;
  context.lineWidth = 4;
  context.lineCap = 'round';
  context.lineJoin = 'round';
  context.beginPath();
  context.moveTo(-half, -half);
  context.lineTo(half, -half);
  context.lineTo(half, half - fold);
  context.lineTo(half - fold, half);
  context.lineTo(-half, half);
  context.closePath();
  context.moveTo(half - fold, half);
  context.lineTo(half - fold, half - fold);
  context.lineTo(half, half - fold);
  context.moveTo(-half + 8, -5);
  context.lineTo(half - 9, -5);
  context.moveTo(-half + 8, 7);
  context.lineTo(half - 16, 7);
  context.stroke();
  context.restore();
}

function drawSettingsIcon(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  radius: number,
) {
  context.save();
  context.translate(x, y);
  context.strokeStyle = COLORS.textSoft;
  context.fillStyle = COLORS.textSoft;
  context.lineWidth = 4;
  context.lineCap = 'round';
  for (let index = 0; index < 8; index += 1) {
    const angle = (index / 8) * Math.PI * 2;
    context.save();
    context.rotate(angle);
    roundedRect(
      context,
      -2.5,
      -radius - 5,
      5,
      9,
      2,
      COLORS.textSoft,
    );
    context.restore();
  }
  context.beginPath();
  context.arc(0, 0, radius, 0, Math.PI * 2);
  context.stroke();
  context.beginPath();
  context.arc(0, 0, radius * 0.34, 0, Math.PI * 2);
  context.stroke();
  context.restore();
}

function drawCollapseIcon(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  size: number,
) {
  context.save();
  context.translate(x, y);
  context.strokeStyle = COLORS.textSoft;
  context.lineWidth = 4;
  context.lineCap = 'round';
  context.lineJoin = 'round';
  context.beginPath();
  context.moveTo(-size, -size * 0.8);
  context.lineTo(0, -size * 0.14);
  context.lineTo(size, -size * 0.8);
  context.moveTo(-size, size * 0.8);
  context.lineTo(0, size * 0.14);
  context.lineTo(size, size * 0.8);
  context.stroke();
  context.restore();
}

function drawTagIcon(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  size: number,
  color: string,
) {
  const halfHeight = size * 0.34;
  const left = -size * 0.5;
  const shoulder = size * 0.16;
  const tip = size * 0.52;
  context.save();
  context.translate(x, y);
  context.strokeStyle = color;
  context.lineWidth = 4;
  context.lineJoin = 'round';
  context.lineCap = 'round';
  context.beginPath();
  context.moveTo(left, -halfHeight);
  context.lineTo(shoulder, -halfHeight);
  context.lineTo(tip, 0);
  context.lineTo(shoulder, halfHeight);
  context.lineTo(left, halfHeight);
  context.closePath();
  context.stroke();
  context.beginPath();
  context.arc(left + size * 0.18, 0, 3.2, 0, Math.PI * 2);
  context.stroke();
  context.restore();
}

function drawCopyIcon(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  size: number,
) {
  context.save();
  context.strokeStyle = COLORS.textSoft;
  context.lineWidth = 4;
  roundedRect(
    context,
    x - size * 0.5,
    y - size * 0.34,
    size * 0.72,
    size * 0.78,
    4,
    'transparent',
    COLORS.textSoft,
  );
  roundedRect(
    context,
    x - size * 0.2,
    y - size * 0.62,
    size * 0.72,
    size * 0.78,
    4,
    'transparent',
    COLORS.textSoft,
  );
  context.restore();
}

function drawMoreIcon(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
) {
  context.save();
  context.fillStyle = COLORS.textSoft;
  [-10, 0, 10].forEach((offset) => {
    context.beginPath();
    context.arc(x + offset, y, 3.2, 0, Math.PI * 2);
    context.fill();
  });
  context.restore();
}

function drawTag(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  label: string,
  color: string,
) {
  context.font = '700 22px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
  const width = Math.min(180, context.measureText(label).width + 52);
  roundedRect(context, x, y, width, 38, 19, `${color}20`, `${color}aa`);
  context.beginPath();
  context.arc(x + 18, y + 19, 5, 0, Math.PI * 2);
  context.fillStyle = color;
  context.fill();
  context.fillStyle = color;
  context.fillText(label, x + 31, y + 27);
  return width;
}

function createCanvasTexture(
  width: number,
  height: number,
  draw: (context: CanvasRenderingContext2D) => void,
) {
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(width * TEXTURE_PIXEL_RATIO);
  canvas.height = Math.round(height * TEXTURE_PIXEL_RATIO);
  const context = canvas.getContext('2d');
  if (!context) {
    throw new Error('Floatick product scene could not create a 2D canvas.');
  }
  context.scale(TEXTURE_PIXEL_RATIO, TEXTURE_PIXEL_RATIO);
  context.clearRect(0, 0, width, height);
  draw(context);
  const texture = new CanvasTexture(canvas);
  texture.colorSpace = SRGBColorSpace;
  texture.anisotropy = TEXTURE_ANISOTROPY;
  texture.minFilter = LinearMipmapLinearFilter;
  texture.magFilter = LinearFilter;
  return texture;
}

function createContactShadowTexture() {
  return createCanvasTexture(1024, 512, (context) => {
    context.save();
    context.translate(512, 256);
    context.scale(1, 0.34);
    const gradient = context.createRadialGradient(0, 0, 0, 0, 0, 470);
    gradient.addColorStop(0, 'rgba(1, 13, 16, 0.26)');
    gradient.addColorStop(0.46, 'rgba(3, 23, 27, 0.13)');
    gradient.addColorStop(0.78, 'rgba(5, 31, 35, 0.04)');
    gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
    context.fillStyle = gradient;
    context.beginPath();
    context.arc(0, 0, 470, 0, Math.PI * 2);
    context.fill();
    context.restore();
  });
}

function createMainPanelTexture(copy: ProductSceneCopy) {
  return createCanvasTexture(1000, 1340, (context) => {
    context.save();
    context.fillStyle = COLORS.panel;
    context.fillRect(0, 0, 1000, 1340);

    const headerGradient = context.createLinearGradient(0, 0, 1000, 0);
    headerGradient.addColorStop(0, '#22373a');
    headerGradient.addColorStop(1, '#182a2d');
    context.fillStyle = headerGradient;
    context.fillRect(0, 0, 1000, 190);

    roundedRect(context, 58, 46, 102, 102, 28, '#183136', '#426568');
    drawCheckmark(context, 83, 77, 52, COLORS.accent);

    context.fillStyle = COLORS.textSoft;
    context.font =
      '650 31px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.remaining, 190, 110);

    context.globalAlpha = 0.72;
    drawArchiveIcon(context, 688, 94, 32);
    drawStickyBoardIcon(context, 766, 94, 32);
    drawSettingsIcon(context, 844, 94, 15);
    drawCollapseIcon(context, 922, 94, 12);
    context.globalAlpha = 1;

    roundedRect(
      context,
      58,
      232,
      626,
      104,
      27,
      COLORS.panelRaised,
      COLORS.line,
    );
    drawSearchIcon(context, 103, 279, 14);
    context.fillStyle = COLORS.textMuted;
    context.font =
      '540 30px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.search, 151, 291);

    roundedRect(
      context,
      704,
      232,
      104,
      104,
      27,
      COLORS.panelRaised,
      COLORS.line,
    );
    drawTagIcon(context, 756, 284, 34, COLORS.textSoft);

    roundedRect(context, 826, 232, 118, 104, 34, '#34554f');
    context.fillStyle = COLORS.text;
    context.font =
      '720 28px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    drawCenteredIconLabel(
      context,
      copy.newTodo,
      885,
      284,
      18,
      10,
      COLORS.text,
      drawPlusIcon,
    );

    context.fillStyle = COLORS.textMuted;
    context.font =
      '700 26px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.today, 64, 416);
    context.fillStyle = '#526467';
    context.fillRect(156, 399, 788, 2);

    const tagColors = [COLORS.accent, COLORS.blue, COLORS.purple];
    const taskStarts = [456, 718, 980];
    copy.tasks.forEach((task, index) => {
      const y = taskStarts[index];
      const completed = index === 1;
      if (index > 0) {
        context.fillStyle = 'rgba(202, 229, 226, 0.07)';
        context.fillRect(60, y - 28, 884, 2);
      }
      if (index === 0) {
        roundedRect(
          context,
          56,
          y - 18,
          888,
          174,
          22,
          'rgba(255, 255, 255, 0.035)',
        );
      }

      roundedRect(
        context,
        66,
        y,
        54,
        54,
        16,
        completed ? COLORS.accent : 'transparent',
        completed ? COLORS.accent : '#6e7e80',
      );
      if (completed) {
        drawCheckmark(context, 80, y + 16, 27, COLORS.ink);
      }

      context.fillStyle = completed ? COLORS.textMuted : COLORS.text;
      context.font =
        '690 31px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
      context.fillText(task.title, 150, y + 40);
      if (completed) {
        const textWidth = Math.min(600, context.measureText(task.title).width);
        context.fillStyle = COLORS.textMuted;
        context.fillRect(150, y + 24, textWidth, 3);
      }

      const tagWidth = drawTag(
        context,
        150,
        y + 72,
        task.tag,
        tagColors[index],
      );
      drawTagIcon(
        context,
        150 + tagWidth + 25,
        y + 91,
        18,
        COLORS.accent,
      );
      context.fillStyle = COLORS.textMuted;
      context.font =
        '560 23px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
      context.textAlign = 'right';
      context.fillText(task.time, 918, y + 101);
      context.textAlign = 'start';

      if (index === 0) {
        context.globalAlpha = 0.82;
        drawCopyIcon(context, 852, y + 30, 28);
        drawMoreIcon(context, 914, y + 30);
        context.globalAlpha = 1;
      }
    });
    context.restore();
  });
}

function createBoardTexture(copy: ProductSceneCopy) {
  return createCanvasTexture(760, 560, (context) => {
    context.save();
    const gradient = context.createLinearGradient(0, 0, 760, 560);
    gradient.addColorStop(0, '#56609a');
    gradient.addColorStop(1, COLORS.board);
    context.fillStyle = gradient;
    context.fillRect(0, 0, 760, 560);

    context.fillStyle = COLORS.text;
    context.font =
      '760 40px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.boardTitle, 48, 76);

    context.strokeStyle = 'rgba(238, 242, 255, 0.16)';
    context.lineWidth = 2;
    context.beginPath();
    context.moveTo(0, 118);
    context.lineTo(760, 118);
    context.stroke();

    copy.tasks.slice(0, 2).forEach((task, index) => {
      const y = 166 + index * 104;
      const completed = index === 1;
      roundedRect(
        context,
        48,
        y,
        42,
        42,
        12,
        completed ? COLORS.accent : 'transparent',
        completed ? COLORS.accent : 'rgba(235, 240, 255, 0.48)',
      );
      if (completed) drawCheckmark(context, 59, y + 12, 21, COLORS.ink);
      context.fillStyle = completed
        ? 'rgba(238, 242, 255, 0.55)'
        : '#f5f6ff';
      context.font =
        '650 29px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
      context.fillText(task.title, 116, y + 31);
      if (completed) {
        const textWidth = Math.min(520, context.measureText(task.title).width);
        context.fillRect(116, y + 18, textWidth, 3);
      }
    });

    context.fillStyle = 'rgba(239, 241, 255, 0.62)';
    context.font =
      '680 25px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.boardCount, 48, 506);
    context.restore();
  });
}

function createDrawerTexture(copy: ProductSceneCopy) {
  return createCanvasTexture(720, 1040, (context) => {
    context.save();
    const gradient = context.createLinearGradient(0, 0, 720, 1040);
    gradient.addColorStop(0, '#2d4246');
    gradient.addColorStop(1, '#203236');
    context.fillStyle = gradient;
    context.fillRect(0, 0, 720, 1040);

    context.fillStyle = COLORS.text;
    context.font =
      '760 36px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.drawerTitle, 48, 76);
    drawCloseIcon(context, 642, 60, 24, COLORS.textSoft);

    context.fillStyle = 'rgba(205, 229, 226, 0.14)';
    context.fillRect(0, 118, 720, 2);

    context.fillStyle = COLORS.textMuted;
    context.font =
      '680 23px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.titleLabel, 48, 184);
    roundedRect(
      context,
      48,
      210,
      624,
      110,
      22,
      '#162426',
      'rgba(45, 212, 199, 0.62)',
    );
    context.fillStyle = COLORS.textSoft;
    context.font =
      '590 27px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.titleValue, 74, 276);

    context.fillStyle = COLORS.textMuted;
    context.font =
      '680 23px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.fillText(copy.contentLabel, 48, 386);
    roundedRect(
      context,
      48,
      412,
      624,
      334,
      22,
      '#162426',
      COLORS.line,
    );
    context.fillStyle = COLORS.textSoft;
    context.font =
      '540 25px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    const words = copy.contentValue.split(' ');
    let line = '';
    let lineY = 466;
    words.forEach((word) => {
      const nextLine = `${line}${word} `;
      if (context.measureText(nextLine).width > 540 && line) {
        context.fillText(line.trim(), 74, lineY);
        line = `${word} `;
        lineY += 42;
      } else {
        line = nextLine;
      }
    });
    context.fillText(line.trim(), 74, lineY);

    roundedRect(context, 386, 864, 286, 106, 53, COLORS.accent);
    context.font =
      '760 28px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    drawCenteredIconLabel(
      context,
      copy.save,
      529,
      917,
      27,
      16,
      COLORS.ink,
      drawCenteredCheckmark,
    );
    context.restore();
  });
}

function createLogoTexture() {
  return createCanvasTexture(512, 512, (context) => {
    const radial = context.createRadialGradient(196, 150, 30, 256, 256, 250);
    radial.addColorStop(0, '#2a4850');
    radial.addColorStop(0.68, '#183036');
    radial.addColorStop(1, '#0c1d21');
    context.fillStyle = radial;
    context.fillRect(0, 0, 512, 512);
    context.strokeStyle = 'rgba(177, 230, 224, 0.3)';
    context.lineWidth = 15;
    context.beginPath();
    context.arc(256, 256, 224, 0, Math.PI * 2);
    context.stroke();
    drawCheckmark(context, 126, 194, 150, COLORS.accent);
    drawCheckmark(context, 212, 150, 174, COLORS.accent);
  });
}

function createRoundedPanelFaceGeometry(
  width: number,
  height: number,
  radius: number,
) {
  const halfWidth = width / 2;
  const halfHeight = height / 2;
  const clampedRadius = Math.min(radius, halfWidth, halfHeight);
  const shape = new Shape();

  shape.moveTo(-halfWidth + clampedRadius, -halfHeight);
  shape.lineTo(halfWidth - clampedRadius, -halfHeight);
  shape.quadraticCurveTo(
    halfWidth,
    -halfHeight,
    halfWidth,
    -halfHeight + clampedRadius,
  );
  shape.lineTo(halfWidth, halfHeight - clampedRadius);
  shape.quadraticCurveTo(
    halfWidth,
    halfHeight,
    halfWidth - clampedRadius,
    halfHeight,
  );
  shape.lineTo(-halfWidth + clampedRadius, halfHeight);
  shape.quadraticCurveTo(
    -halfWidth,
    halfHeight,
    -halfWidth,
    halfHeight - clampedRadius,
  );
  shape.lineTo(-halfWidth, -halfHeight + clampedRadius);
  shape.quadraticCurveTo(
    -halfWidth,
    -halfHeight,
    -halfWidth + clampedRadius,
    -halfHeight,
  );
  shape.closePath();

  const geometry = new ShapeGeometry(shape, PANEL_FACE_CURVE_SEGMENTS);
  const positions = geometry.getAttribute('position');
  const uvs = new Float32Array(positions.count * 2);
  for (let index = 0; index < positions.count; index += 1) {
    uvs[index * 2] = (positions.getX(index) + halfWidth) / width;
    uvs[index * 2 + 1] = (positions.getY(index) + halfHeight) / height;
  }
  geometry.setAttribute('uv', new BufferAttribute(uvs, 2));
  return geometry;
}

function createPanel(
  width: number,
  height: number,
  depth: number,
  radius: number,
  color: string,
  texture: CanvasTexture,
  disposables: Disposable[],
): ScenePanel {
  const group = new Group();
  const geometry = new RoundedBoxGeometry(width, height, depth, 6, radius);
  const bodyMaterial = new MeshPhysicalMaterial({
    color,
    metalness: 0.12,
    roughness: 0.42,
    clearcoat: 0.38,
    clearcoatRoughness: 0.34,
  });
  const body = new Mesh(geometry, bodyMaterial);
  body.castShadow = true;
  body.receiveShadow = true;
  group.add(body);

  const faceWidth = width - PANEL_FACE_INSET;
  const faceHeight = height - PANEL_FACE_INSET;
  const faceRadius = Math.max(0, radius - PANEL_FACE_INSET / 2);
  const faceGeometry = createRoundedPanelFaceGeometry(
    faceWidth,
    faceHeight,
    faceRadius,
  );
  const faceMaterial = new MeshBasicMaterial({
    map: texture,
    toneMapped: false,
  });
  const face = new Mesh(faceGeometry, faceMaterial);
  face.position.z = depth / 2 + PANEL_FACE_DEPTH_OFFSET;
  group.add(face);

  disposables.push(
    geometry,
    bodyMaterial,
    faceGeometry,
    faceMaterial,
    texture,
  );
  return { group, body };
}

function addBezelBolts(
  parent: Object3D,
  width: number,
  height: number,
  z: number,
  disposables: Disposable[],
) {
  const geometry = new CylinderGeometry(0.065, 0.065, 0.04, 20);
  const material = new MeshStandardMaterial({
    color: '#54706f',
    metalness: 0.95,
    roughness: 0.2,
  });
  const offsets = [
    [-width / 2 + 0.22, height / 2 - 0.22],
    [width / 2 - 0.22, height / 2 - 0.22],
    [-width / 2 + 0.22, -height / 2 + 0.22],
    [width / 2 - 0.22, -height / 2 + 0.22],
  ] as const;
  offsets.forEach(([x, y]) => {
    const bolt = new Mesh(geometry, material);
    bolt.position.set(x, y, z);
    bolt.rotation.x = Math.PI / 2;
    bolt.castShadow = true;
    parent.add(bolt);
  });
  disposables.push(geometry, material);
}

function createRoundedFramePath() {
  const halfWidth = PRODUCT_FRAME.width / 2 - PRODUCT_FRAME.trackInset;
  const halfHeight = PRODUCT_FRAME.height / 2 - PRODUCT_FRAME.trackInset;
  const radius = PRODUCT_FRAME.cornerRadius - PRODUCT_FRAME.trackInset;
  const z = PRODUCT_FRAME.trackZ;
  const path = new CurvePath<Vector3>();

  path.add(
    new LineCurve3(
      new Vector3(-halfWidth + radius, halfHeight, z),
      new Vector3(halfWidth - radius, halfHeight, z),
    ),
  );
  path.add(
    new QuadraticBezierCurve3(
      new Vector3(halfWidth - radius, halfHeight, z),
      new Vector3(halfWidth, halfHeight, z),
      new Vector3(halfWidth, halfHeight - radius, z),
    ),
  );
  path.add(
    new LineCurve3(
      new Vector3(halfWidth, halfHeight - radius, z),
      new Vector3(halfWidth, -halfHeight + radius, z),
    ),
  );
  path.add(
    new QuadraticBezierCurve3(
      new Vector3(halfWidth, -halfHeight + radius, z),
      new Vector3(halfWidth, -halfHeight, z),
      new Vector3(halfWidth - radius, -halfHeight, z),
    ),
  );
  path.add(
    new LineCurve3(
      new Vector3(halfWidth - radius, -halfHeight, z),
      new Vector3(-halfWidth + radius, -halfHeight, z),
    ),
  );
  path.add(
    new QuadraticBezierCurve3(
      new Vector3(-halfWidth + radius, -halfHeight, z),
      new Vector3(-halfWidth, -halfHeight, z),
      new Vector3(-halfWidth, -halfHeight + radius, z),
    ),
  );
  path.add(
    new LineCurve3(
      new Vector3(-halfWidth, -halfHeight + radius, z),
      new Vector3(-halfWidth, halfHeight - radius, z),
    ),
  );
  path.add(
    new QuadraticBezierCurve3(
      new Vector3(-halfWidth, halfHeight - radius, z),
      new Vector3(-halfWidth, halfHeight, z),
      new Vector3(-halfWidth + radius, halfHeight, z),
    ),
  );

  return path;
}

function addConveyorTrack(root: Group, disposables: Disposable[]) {
  const curve = createRoundedFramePath();
  const railGeometry = new TubeGeometry(
    curve,
    240,
    CONVEYOR_RAIL_RADIUS,
    12,
    true,
  );
  const railMaterial = new MeshPhysicalMaterial({
    color: '#476768',
    metalness: 0.9,
    roughness: 0.18,
    clearcoat: 0.6,
  });
  const rail = new Mesh(railGeometry, railMaterial);
  rail.castShadow = true;
  rail.receiveShadow = true;
  root.add(rail);

  const glowGeometry = new TubeGeometry(curve, 240, 0.027, 8, true);
  const glowMaterial = new MeshBasicMaterial({
    color: COLORS.accent,
    transparent: true,
    opacity: 0.62,
  });
  root.add(new Mesh(glowGeometry, glowMaterial));

  const carrierGeometry = new RoundedBoxGeometry(
    0.48,
    0.27,
    CONVEYOR_CARRIER_DEPTH,
    6,
    0.11,
  );
  const carrierMaterials = [
    new MeshPhysicalMaterial({
      color: COLORS.accent,
      metalness: 0.7,
      roughness: 0.18,
      clearcoat: 0.95,
      clearcoatRoughness: 0.12,
    }),
    new MeshPhysicalMaterial({
      color: COLORS.blue,
      metalness: 0.7,
      roughness: 0.18,
      clearcoat: 0.95,
      clearcoatRoughness: 0.12,
    }),
    new MeshPhysicalMaterial({
      color: COLORS.orange,
      metalness: 0.7,
      roughness: 0.18,
      clearcoat: 0.95,
      clearcoatRoughness: 0.12,
    }),
  ];
  const carriers = carrierMaterials.map((material) => {
    const carrier = new Mesh(carrierGeometry, material);
    root.add(carrier);
    return carrier;
  });
  disposables.push(
    railGeometry,
    railMaterial,
    glowGeometry,
    glowMaterial,
    carrierGeometry,
    ...carrierMaterials,
  );

  return { curve, carriers };
}

function buildProductScene(
  stage: HTMLElement,
  canvas: HTMLCanvasElement,
  copy: ProductSceneCopy,
) {
  const reducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)',
  ).matches;
  const compactViewport = window.matchMedia('(max-width: 720px)').matches;
  const disposables: Disposable[] = [];

  const renderer = new WebGLRenderer({
    canvas,
    antialias: !compactViewport,
    alpha: true,
    powerPreference: 'high-performance',
  });
  renderer.outputColorSpace = SRGBColorSpace;
  renderer.toneMapping = ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.16;
  renderer.shadowMap.enabled = !compactViewport;
  renderer.shadowMap.type = PCFSoftShadowMap;
  renderer.setPixelRatio(
    Math.min(
      window.devicePixelRatio,
      compactViewport
        ? COMPACT_RENDER_PIXEL_RATIO
        : DESKTOP_RENDER_PIXEL_RATIO,
    ),
  );

  const scene = new Scene();
  scene.fog = new FogExp2('#071113', 0.018);

  const camera = new PerspectiveCamera(31, 1, 0.1, 50);
  camera.position.set(0, 0.25, compactViewport ? 21.8 : 20.8);
  camera.lookAt(0, 0, 0);

  const root = new Group();
  root.rotation.set(-0.035, -0.055, -0.018);
  root.scale.setScalar(compactViewport ? 0.67 : 0.82);
  scene.add(root);

  const ambient = new HemisphereLight('#c5fff9', '#17393d', 1.68);
  scene.add(ambient);

  const keyLight = new SpotLight('#c8fff9', 86, 32, 0.56, 0.65, 1.3);
  keyLight.position.set(-6.5, 8.4, 10.5);
  keyLight.target.position.set(-0.6, 0.2, 0);
  keyLight.castShadow = !compactViewport;
  keyLight.shadow.mapSize.set(1024, 1024);
  keyLight.shadow.bias = -0.0008;
  scene.add(keyLight, keyLight.target);

  const rimLight = new PointLight(COLORS.accent, 44, 22, 1.5);
  rimLight.position.set(5.8, -2.6, 6.2);
  scene.add(rimLight);

  const blueLight = new PointLight('#6978ff', 25, 18, 1.7);
  blueLight.position.set(-5.4, -3.6, 3.3);
  scene.add(blueLight);

  const platformGeometry = new RoundedBoxGeometry(
    PRODUCT_FRAME.width,
    PRODUCT_FRAME.height,
    PRODUCT_FRAME.depth,
    8,
    PRODUCT_FRAME.cornerRadius,
  );
  const platformMaterial = new MeshPhysicalMaterial({
    color: '#245057',
    emissive: '#0b2a2e',
    emissiveIntensity: 0.42,
    metalness: 0.44,
    roughness: 0.25,
    clearcoat: 0.72,
    clearcoatRoughness: 0.2,
  });
  const platform = new Mesh(platformGeometry, platformMaterial);
  platform.position.z = -1.36;
  platform.receiveShadow = true;
  platform.castShadow = true;
  root.add(platform);
  addBezelBolts(
    platform,
    PRODUCT_FRAME.width,
    PRODUCT_FRAME.height,
    PRODUCT_FRAME.depth / 2 + 0.02,
    disposables,
  );
  disposables.push(platformGeometry, platformMaterial);

  const innerPlatformGeometry = new RoundedBoxGeometry(
    PRODUCT_FRAME.width - PRODUCT_FRAME.innerInset,
    PRODUCT_FRAME.height - PRODUCT_FRAME.innerInset,
    PRODUCT_FRAME.innerDepth,
    6,
    PRODUCT_FRAME.innerCornerRadius,
  );
  const innerPlatformMaterial = new MeshPhysicalMaterial({
    color: '#20474c',
    emissive: '#09272b',
    emissiveIntensity: 0.3,
    metalness: 0.36,
    roughness: 0.3,
    clearcoat: 0.58,
    clearcoatRoughness: 0.24,
  });
  const innerPlatform = new Mesh(
    innerPlatformGeometry,
    innerPlatformMaterial,
  );
  innerPlatform.position.z = -1.08;
  innerPlatform.receiveShadow = true;
  root.add(innerPlatform);
  disposables.push(innerPlatformGeometry, innerPlatformMaterial);

  const conveyorAssembly = new Group();
  root.add(conveyorAssembly);
  const { curve, carriers } = addConveyorTrack(
    conveyorAssembly,
    disposables,
  );
  const productContent = new Group();
  productContent.scale.setScalar(0.86);
  productContent.position.z = 0.12;
  root.add(productContent);

  const mainPanel = createPanel(
    5.45,
    7.25,
    0.48,
    0.34,
    COLORS.panel,
    createMainPanelTexture(copy),
    disposables,
  );
  mainPanel.group.position.copy(PANEL_LAYOUT.main);
  mainPanel.group.rotation.set(0.018, -0.06, -0.012);
  productContent.add(mainPanel.group);

  const boardPanel = createPanel(
    3.65,
    2.72,
    0.46,
    0.28,
    COLORS.board,
    createBoardTexture(copy),
    disposables,
  );
  boardPanel.group.position.copy(
    reducedMotion ? PANEL_LAYOUT.boardExpanded : PANEL_LAYOUT.boardCollapsed,
  );
  boardPanel.group.rotation.set(
    -0.025,
    reducedMotion ? 0.22 : 0.015,
    reducedMotion ? 0.035 : -0.018,
  );
  productContent.add(boardPanel.group);

  const drawerPanel = createPanel(
    3.55,
    5.32,
    0.5,
    0.3,
    COLORS.panelRaised,
    createDrawerTexture(copy),
    disposables,
  );
  drawerPanel.group.position.copy(
    reducedMotion ? PANEL_LAYOUT.drawerExpanded : PANEL_LAYOUT.drawerCollapsed,
  );
  drawerPanel.group.rotation.set(
    0.025,
    reducedMotion ? -0.22 : -0.02,
    reducedMotion ? -0.018 : 0.016,
  );
  productContent.add(drawerPanel.group);

  const logoTexture = createLogoTexture();
  const coinGeometry = new CylinderGeometry(0.84, 0.84, 0.34, 64, 1);
  const coinBodyMaterial = new MeshPhysicalMaterial({
    color: '#24444a',
    metalness: 0.26,
    roughness: 0.34,
    clearcoat: 0.62,
  });
  const coin = new Mesh(coinGeometry, coinBodyMaterial);
  coin.rotation.x = Math.PI / 2;
  coin.castShadow = true;

  const coinFaceGeometry = new CircleGeometry(0.825, 64);
  const coinFaceMaterial = new MeshBasicMaterial({
    map: logoTexture,
    toneMapped: false,
  });
  const coinFace = new Mesh(coinFaceGeometry, coinFaceMaterial);
  coinFace.position.z = 0.18;

  const coinAssembly = new Group();
  coinAssembly.position.copy(COIN_BASE_POSITION);
  coinAssembly.rotation.z = -0.12;
  coinAssembly.add(coin, coinFace);
  productContent.add(coinAssembly);
  disposables.push(
    logoTexture,
    coinGeometry,
    coinBodyMaterial,
    coinFaceGeometry,
    coinFaceMaterial,
  );

  const badgeGeometry = new RoundedBoxGeometry(0.56, 0.56, 0.18, 4, 0.28);
  const badgeMaterial = new MeshPhysicalMaterial({
    color: COLORS.orange,
    metalness: 0.3,
    roughness: 0.28,
    clearcoat: 0.92,
  });
  const badge = new Mesh(badgeGeometry, badgeMaterial);
  badge.position.set(0.56, 0.61, 0.33);
  badge.castShadow = true;
  coinAssembly.add(badge);
  disposables.push(badgeGeometry, badgeMaterial);

  const badgeTexture = createCanvasTexture(256, 256, (context) => {
    context.fillStyle = '#ffffff';
    context.font =
      '800 108px Inter, -apple-system, BlinkMacSystemFont, sans-serif';
    context.textAlign = 'center';
    context.textBaseline = 'middle';
    context.fillText('3', 128, 138);
  });
  const badgeFaceGeometry = new PlaneGeometry(0.5, 0.5);
  const badgeFaceMaterial = new MeshBasicMaterial({
    map: badgeTexture,
    transparent: true,
    toneMapped: false,
  });
  const badgeFace = new Mesh(badgeFaceGeometry, badgeFaceMaterial);
  badgeFace.position.set(0.56, 0.61, 0.43);
  coinAssembly.add(badgeFace);
  disposables.push(badgeTexture, badgeFaceGeometry, badgeFaceMaterial);

  const contactShadowTexture = createContactShadowTexture();
  const contactShadowGeometry = new PlaneGeometry(15.6, 6.8);
  const contactShadowMaterial = new MeshBasicMaterial({
    map: contactShadowTexture,
    transparent: true,
    opacity: 0.42,
    depthWrite: false,
    toneMapped: false,
  });
  const contactShadow = new Mesh(
    contactShadowGeometry,
    contactShadowMaterial,
  );
  contactShadow.rotation.x = -Math.PI / 2;
  contactShadow.position.set(0, -4.18, -0.16);
  scene.add(contactShadow);
  disposables.push(
    contactShadowTexture,
    contactShadowGeometry,
    contactShadowMaterial,
  );

  const pointerTarget = new Vector2();
  const pointerCurrent = new Vector2();
  const pointerRaycaster = new Raycaster();
  let scrollDepth = 0;
  let renderedWidth = 0;
  let renderedHeight = 0;
  let animationFrame = 0;
  let scrollFrame = 0;
  let isVisible = true;
  let isDisposed = false;
  let isExpanded = reducedMotion;
  const clock = new Clock();
  const animatedBoardTarget = new Vector3();
  const animatedDrawerTarget = new Vector3();

  const render = () => {
    renderer.render(scene, camera);
  };

  const resize = () => {
    const width = Math.max(1, stage.clientWidth);
    const height = Math.max(1, stage.clientHeight);
    if (width === renderedWidth && height === renderedHeight) return;
    renderedWidth = width;
    renderedHeight = height;
    renderer.setSize(width, height, false);
    camera.aspect = width / height;
    camera.fov = width < 560 ? 40 : 31;
    camera.position.z = width < 560 ? 21.8 : 20.8;
    root.scale.setScalar(width < 560 ? 0.67 : width < 760 ? 0.76 : 0.82);
    camera.updateProjectionMatrix();
    render();
  };

  const updateScrollDepth = () => {
    scrollFrame = 0;
    const bounds = stage.getBoundingClientRect();
    const viewportCenter = window.innerHeight / 2;
    const stageCenter = bounds.top + bounds.height / 2;
    scrollDepth = MathUtils.clamp(
      (stageCenter - viewportCenter) / window.innerHeight,
      -1,
      1,
    );
  };

  const requestScrollDepth = () => {
    if (scrollFrame) return;
    scrollFrame = window.requestAnimationFrame(updateScrollDepth);
  };

  const animate = () => {
    animationFrame = 0;
    if (isDisposed || !isVisible) return;
    const elapsed = clock.getElapsedTime();

    pointerCurrent.lerp(pointerTarget, 0.065);
    root.rotation.x =
      -0.035 + pointerCurrent.y * 0.09 + scrollDepth * 0.035;
    root.rotation.y = -0.055 + pointerCurrent.x * 0.14;
    root.position.y = Math.sin(elapsed * 0.55) * 0.045 - scrollDepth * 0.12;

    mainPanel.group.position.y =
      PANEL_LAYOUT.main.y + Math.sin(elapsed * 0.72) * 0.035;

    const boardTarget = isExpanded
      ? PANEL_LAYOUT.boardExpanded
      : PANEL_LAYOUT.boardCollapsed;
    const drawerTarget = isExpanded
      ? PANEL_LAYOUT.drawerExpanded
      : PANEL_LAYOUT.drawerCollapsed;
    animatedBoardTarget.copy(boardTarget);
    animatedDrawerTarget.copy(drawerTarget);
    if (isExpanded) {
      animatedBoardTarget.y += Math.sin(elapsed * 0.82 + 1.4) * 0.045;
      animatedDrawerTarget.y += Math.sin(elapsed * 0.68 + 2.2) * 0.04;
    }
    boardPanel.group.position.lerp(animatedBoardTarget, 0.075);
    drawerPanel.group.position.lerp(animatedDrawerTarget, 0.075);
    boardPanel.group.rotation.y = MathUtils.lerp(
      boardPanel.group.rotation.y,
      isExpanded ? 0.22 : 0.015,
      0.075,
    );
    boardPanel.group.rotation.z = MathUtils.lerp(
      boardPanel.group.rotation.z,
      isExpanded ? 0.035 : -0.018,
      0.075,
    );
    drawerPanel.group.rotation.y = MathUtils.lerp(
      drawerPanel.group.rotation.y,
      isExpanded ? -0.22 : -0.02,
      0.075,
    );
    drawerPanel.group.rotation.z = MathUtils.lerp(
      drawerPanel.group.rotation.z,
      isExpanded ? -0.018 : 0.016,
      0.075,
    );

    coinAssembly.position.y =
      COIN_BASE_POSITION.y + Math.sin(elapsed * 1.2) * 0.1;
    coinAssembly.rotation.z =
      -0.12 + Math.sin(elapsed * 0.64) * 0.08;

    carriers.forEach((carrier, index) => {
      const progress = (elapsed * 0.025 + index / carriers.length) % 1;
      const position = curve.getPointAt(progress);
      const tangent = curve.getTangentAt(progress);
      carrier.position.copy(position);
      carrier.position.z += CONVEYOR_CARRIER_Z_OFFSET;
      carrier.rotation.set(0, 0, Math.atan2(tangent.y, tangent.x));
    });

    render();
    animationFrame = window.requestAnimationFrame(animate);
  };

  const startAnimation = () => {
    if (reducedMotion || animationFrame || !isVisible || isDisposed) return;
    clock.start();
    animationFrame = window.requestAnimationFrame(animate);
  };

  const stopAnimation = () => {
    if (!animationFrame) return;
    window.cancelAnimationFrame(animationFrame);
    animationFrame = 0;
    clock.stop();
  };

  const resetPointer = () => pointerTarget.set(0, 0);

  const handlePointerMove = (event: PointerEvent) => {
    if (event.pointerType === 'touch' || reducedMotion) return;
    const bounds = stage.getBoundingClientRect();
    pointerTarget.set(
      ((event.clientX - bounds.left) / bounds.width - 0.5) * 2,
      -((event.clientY - bounds.top) / bounds.height - 0.5) * 2,
    );
    pointerRaycaster.setFromCamera(pointerTarget, camera);
    if (pointerRaycaster.intersectObject(platform, false).length > 0) {
      isExpanded = true;
      return;
    }
    isExpanded = false;
    resetPointer();
  };

  const collapsePanels = () => {
    isExpanded = false;
    resetPointer();
  };

  const resizeObserver = new ResizeObserver(resize);
  resizeObserver.observe(stage);

  const visibilityObserver = new IntersectionObserver(
    ([entry]) => {
      isVisible = entry?.isIntersecting ?? false;
      if (isVisible) {
        resize();
        startAnimation();
      } else {
        stopAnimation();
      }
    },
    { rootMargin: '120px', threshold: 0.01 },
  );
  visibilityObserver.observe(stage);

  stage.addEventListener('pointermove', handlePointerMove, { passive: true });
  stage.addEventListener('pointerleave', collapsePanels);
  window.addEventListener('scroll', requestScrollDepth, { passive: true });

  resize();
  updateScrollDepth();
  stage.classList.add('is-webgl-ready');
  if (reducedMotion) {
    render();
  } else {
    startAnimation();
  }

  const cleanup = () => {
    if (isDisposed) return;
    isDisposed = true;
    stopAnimation();
    if (scrollFrame) window.cancelAnimationFrame(scrollFrame);
    resizeObserver.disconnect();
    visibilityObserver.disconnect();
    stage.removeEventListener('pointermove', handlePointerMove);
    stage.removeEventListener('pointerleave', collapsePanels);
    window.removeEventListener('scroll', requestScrollDepth);
    disposables.forEach((disposable) => disposable.dispose());
    renderer.dispose();
  };

  window.addEventListener('pagehide', cleanup, { once: true });
}

export function initializeProductHeroScenes() {
  const stages = document.querySelectorAll<HTMLElement>(SELECTORS.stage);
  stages.forEach((stage) => {
    if (mountedStages.has(stage)) return;
    const canvas = stage.querySelector<HTMLCanvasElement>(SELECTORS.canvas);
    if (!canvas) return;
    mountedStages.add(stage);
    try {
      buildProductScene(stage, canvas, readSceneCopy(stage));
    } catch (error) {
      stage.classList.add('has-webgl-error');
      console.error('Floatick product scene could not be initialized.', error);
    }
  });
}
