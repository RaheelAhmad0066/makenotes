enum GraphicElementType {
    text,
    rectangle,
    drawing,
    image,
    video,
    explanation,
}

type Color = {
    value?: number;
};

type BorderRadius = {
    bottomLeft: {
        x: number;
    };
};

type BoxDecoration = {
    color?: Color;
    borderRadius?: BorderRadius;
};

type Rect = {
    left: number;
    top: number;
    width: number;
    height: number;
};

type GraphicElementModel = {
    type: GraphicElementType;
    bounds: Rect;
    decoration: BoxDecoration;
    opacity: number;
    visibility: boolean;
    rotation: number;
};

type PencilKitElementModel = GraphicElementModel & {
    data?: string;
};

type Sketch = Record<string, any>;

type ScribbleElementModel = GraphicElementModel & {
    sketch: Sketch;
};

type Size = {
    width: number;
    height: number;
}

type PageModel = {
    id?: string;
    referenceId?: string;
    order: number;
    size: Size;
    graphicElements: GraphicElementModel[];
    sketch: ScribbleElementModel;
    pencilKit: PencilKitElementModel;
    backgroundImageUrl?: string;
};
