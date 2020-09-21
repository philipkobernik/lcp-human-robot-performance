# LCP Performance Operator

This repo is a NextJS app that exports to static html site using `npm run build`.

It has one page, an interface for controlling the focus part and a record start/stop toggle button.

This UI is wired up to our firebase repo, the values of which are used to drive our mapping prototypes that allow a dancer to fabricate a form on the LCP via their movements.

## Install / Dev
`npm install`

`npm run dev`

## Build

`npm run build`

## Deploy

`cd out`

then

`surge .`

(requires surge to be installed as a global npm package: `npm install -g surge`)