# Build resources

The resources in this folder are used for building WHATWG standards.

## `deploy.sh`

The `deploy.sh` script is used by most WHATWG standards and is meant to run either on Travis CI, or locally for preview purposes. It performs the following steps:

- Running [Bikeshed](https://github.com/tabatkins/bikeshed), through its [web API](https://api.csswg.org/bikeshed/), to produce:
  - If on master, the built Living Standard, as well as a commit snapshot
  - Otherwise, a branch snapshot of the standard
- Running the [Nu HTML checker](http://checker.html5.org/) on the build results
- Deploying the build results to the WHATWG web server

For Travis CI deploys, it is dependent on the following environment setup:

- `deploy_key.enc` must contain a SSH private key, [encrypted for Travis](https://docs.travis-ci.com/user/encrypting-files/) for the appropriate repository.
- The environment variable `$ENCRYPTION_LABEL` must contain the encryption label produced by the Travis encryption process.

For GitHub Actions deploys, the following environment variables are required:
- `$SERVER` is the server to deploy to.
- `$SERVER_PUBLIC_KEY` is the public key of the deploy server, in the format of `known_hosts`.
- `$SERVER_DEPLOY_KEY` is the deploy key for the server, which will be passed to `ssh-add`.

Optional environment variables:
- `$EXTRA_FILES` are extra files to copy for each build. Shell wildcards are allowed, and directory structure will be preserved. Example: `EXTRA_FILES="images/*.png"`.
- `$POST_BUILD_STEP` is an extra step to run after each build. Evaluated with the `$DIR` variable set to the build directory. Example: `POST_BUILD_STEP='python generate-stuff.py "$DIR"'`.

To cause particular errors or warnings emitted by the HTML checker to be suppressed, add a file named `.htmlcheckerfilter` at the root of the repo for a particular standard, and put filter patterns into it, as documented at https://github.com/validator/validator/wiki/Message-filtering#using-the---filterfile-option.

An example `.github/workflows/deploy.yml` file that uses this script would then be as follows:

```yaml
name: deploy
on:
  push:
    branches:
      - master
jobs:
  deploy:
    runs-on: ubuntu-20.04
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: 2
    - run: make deploy
      env:
        SERVER: ${{ secrets.MARQUEE_SERVER }}
        SERVER_PUBLIC_KEY: ${{ secrets.MARQUEE_PUBLIC_KEY }}
        SERVER_DEPLOY_KEY: ${{ secrets.MARQUEE_DEPLOY_KEY }}
```

This assumes that the `Makefile` from [spec-factory](https://github.com/whatwg/spec-factory) is used, which fetches and runs `deploy.sh`.

An example `.travis.yml` file that uses this script would then be as follows:

```yaml
language: generic

env:
  global:
    - ENCRYPTION_LABEL="1337deadb33f"

script:
  - curl --remote-name --fail https://resources.whatwg.org/build/deploy.sh && bash ./deploy.sh

branches:
  only:
    - master

notifications:
  email:
    on_success: never
    on_failure: always
```

Similarly, a local deploy can be performed with

```bash
curl --remote-name --fail https://resources.whatwg.org/build/deploy.sh && bash ./deploy.sh
```

or more typically `make deploy`.

Whether the script is running a local vs. Travis deploy is determined by checking [the `$TRAVIS` environment variable](https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables).

## `review.sh`

The `review.sh` script is also used by most WHATWG standards and is meant to be run locally to generate a new [Review Draft](https://whatwg.org/workstream-policy#review-drafts).

It can be run with

```bash
curl --remote-name --fail https://resources.whatwg.org/build/review.sh && bash ./review.sh
```

or more typically `make review`.

Please see https://github.com/whatwg/meta/blob/master/MAINTAINERS.md for information on creating and announcing Review Drafts.
