# :construction_worker: :closed_lock_with_key: __Based Applications Contracts__

:construction: CAUTION: This repo is currently under **heavy development!** :construction:

&nbsp;

## :page_with_curl:  _Instructions_

**1)** Fire up your favorite console & clone this repo somewhere:

__`❍ git clone https://github.com/ssvlabs/based-applications.git`__

**2)** After selecting the right branch, enter this directory & install dependencies:

__`❍ forge install`__

**3)** Compile the contracts:

__`❍ forge build`__

**4)** Set the tests going!

__`❍ forge test`__

&nbsp;

## :page_with_curl:  _Generate Docs_

**1)** Enter this directory & install node dependencies:

__`❍ npm install`__

**2)** Compile the contracts:

__`❍ npm run generate-docs`__

**3)** You can find the newly generated docs with `@natspec` in `docs`

&nbsp;

## :runner: __Run Github Workflows locally:__

**Pre-flight.** Make sure you have Docker and Act installed: 

**`❍ brew install docker act`**

**1.** Go into the ms-contracts folder and set the environment:

**`❍ act -P ubuntu-latest=nektos/act-environments-ubuntu:22.04`**

**2.** Run simulation:

**`❍ act push`**

&nbsp;