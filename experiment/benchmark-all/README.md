#  Notes

- `out` is a soft link that points to `/mnt/yotta_1/lilian/projects/diffdock-pp-benchmark/experiment/benchmark-all/out`

It's safe to run 2 jobs at the same time on the same GPU card.

Use the script `benchmark-all/run.sh` to run the benchmark.

Command:

```sh
zsh benchmark-all/run.sh -g 0 -f abdbids.txt-00
zsh benchmark-all/run.sh -g 1 -f abdbids.txt-01
```

- `-g`: GPU index e.g. 0, 1, all
- `-f`: AbDb id list file path e.g. abdbids.txt-00, abdbids.txt-01

I've already split the entire list of AbDb IDs into two files, `abdbids.txt-00` and `abdbids.txt-01` here. Just to distribute them onto two GPU cards to run at the same time.
