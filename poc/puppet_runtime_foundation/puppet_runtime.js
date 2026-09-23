export class PuppetRuntime {
  constructor(parts, options = {}) {
    this.parts = parts;
    this.time = 0;
    this.action = 'idle';
    this.actionTime = 0;
    this.spring = options.spring ?? 12;
  }

  setAction(name) {
    if (this.action === name) return;
    this.action = name;
    this.actionTime = 0;
  }

  tick(dt) {
    const safeDt = Math.min(Math.max(dt, 0), 0.05);
    this.time += safeDt;
    this.actionTime += safeDt;

    const breath = Math.sin(this.time * 1.7) * 0.012;
    const sway = Math.sin(this.time * 1.15) * 0.018;

    this.pose('torso', { rotation: sway, scaleY: 1 + breath });

    if (this.action === 'talk') {
      this.pose('head', {
        rotation: Math.sin(this.actionTime * 2.1) * 0.045,
        y: Math.sin(this.actionTime * 2.8) * 1.5,
      });
      this.pose('armR', {
        rotation: -0.18 + Math.sin(this.actionTime * 2.4) * 0.16,
      });
    } else if (this.action === 'gesture') {
      const reach = Math.max(0, Math.sin(this.actionTime * 1.45));
      this.pose('armR', { rotation: -0.55 * reach });
      this.pose('handR', { rotation: -0.22 * reach });
      this.pose('head', { rotation: 0.035 * reach });
    } else if (this.action === 'eat') {
      const reach = Math.max(0, Math.sin(this.actionTime * 1.25));
      this.pose('armR', { rotation: -0.75 * reach });
      this.pose('handR', { rotation: -0.4 * reach });
      this.pose('head', { rotation: -0.09 * reach });
    } else if (this.action === 'listen') {
      this.pose('head', { rotation: -0.055 + Math.sin(this.actionTime * .8) * .025 });
      this.pose('armR', { rotation: .04 });
    } else {
      this.pose('head', { rotation: Math.sin(this.time * .65) * .018 });
      this.pose('armR', { rotation: Math.sin(this.time * .9) * .025 });
    }

    return this.parts;
  }

  pose(id, delta) {
    const part = this.parts[id];
    if (!part) return;
    part.runtime = { ...(part.runtime || {}), ...delta };
  }
}

export const puppetAssetSchema = {
  schemaVersion: '1',
  parts: {
    head: { required: true, pivot: 'neck' },
    torso: { required: true, pivot: 'spine' },
    armR: { required: false, pivot: 'shoulderR' },
    handR: { required: false, pivot: 'elbowR' },
    armL: { required: false, pivot: 'shoulderL' },
    handL: { required: false, pivot: 'elbowL' },
    legR: { required: false, pivot: 'hipR' },
    legL: { required: false, pivot: 'hipL' }
  },
  actions: ['idle', 'walk', 'talk', 'gesture', 'eat', 'listen']
};
