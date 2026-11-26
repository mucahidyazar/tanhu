#!/usr/bin/env python3
"""
Meshy dağıtıcısı: onaylanan her konsepti (assets/_concepts/<id>.png + <id>.ok işareti) otomatik olarak
tools/meshy_pipeline.py ile 3B'ye çevirir. Aynı anda en fazla N üretim çalışır; geçici hatada (ağ vb.)
üretim kaldığı yerden yeniden başlatılır (araç görevleri asla iki kez oluşturmaz). Bütçe/bakiye ya da
"belirsiz görev" durumunda o varlık için durur ve günlüğe yazar.

Kullanım: python3 tools/meshy_dispatch.py --env-file F [--parallel 8] [--ids a,b,c]
Her varlığın günlüğü: assets/_meshy_raw/<id>/run.log ; genel özet: assets/_meshy_raw/dispatch.log
"""
import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "tools", "asset_plan.json")
CONCEPTS = os.path.join(ROOT, "assets", "_concepts")
RAW = os.path.join(ROOT, "assets", "_meshy_raw")
STOP_WORDS = ("BÜTÇE", "BAKİYE", "belirsiz", "yine başarısız", "başarısız:", "uzun süre meşgul")
MAX_RESTARTS = 4


def log(msg):
    os.makedirs(RAW, exist_ok=True)
    line = time.strftime("%H:%M:%S ") + msg
    print(line, flush=True)
    with open(os.path.join(RAW, "dispatch.log"), "a", encoding="utf-8") as fh:
        fh.write(line + "\n")


def run_log(asset_id):
    return os.path.join(RAW, asset_id, "run.log")


def finished(asset_id):
    p = run_log(asset_id)
    return os.path.exists(p) and ("[tamam] %s" % asset_id) in open(p, encoding="utf-8", errors="replace").read()


def blocked(asset_id):
    p = run_log(asset_id)
    if not os.path.exists(p):
        return False
    tail = open(p, encoding="utf-8", errors="replace").read()[-3000:]
    return any(w in tail for w in STOP_WORDS)


def main():
    args = sys.argv[1:]
    opts = {}
    while args:
        k = args.pop(0)
        opts[k.lstrip("-")] = args.pop(0)
    env_file = opts["env-file"]
    parallel = int(opts.get("parallel", 8))
    plan = json.load(open(PLAN, encoding="utf-8"))
    ids = opts["ids"].split(",") if "ids" in opts else [a["id"] for a in plan["assets"]]
    running = {}
    restarts = {i: 0 for i in ids}
    log("başladı: %d varlık, en fazla %d paralel" % (len(ids), parallel))
    while True:
        # Bitenleri topla.
        for i, proc in list(running.items()):
            if proc.poll() is None:
                continue
            del running[i]
            if finished(i):
                log("tamam: %s" % i)
            elif blocked(i):
                log("DURDU (elle bakılmalı): %s" % i)
            else:
                restarts[i] += 1
                log("hata, yeniden denenecek (%d/%d): %s" % (restarts[i], MAX_RESTARTS, i))
        pending = [i for i in ids if i not in running and not finished(i) and not blocked(i) and restarts[i] < MAX_RESTARTS]
        ready = [i for i in pending if os.path.exists(os.path.join(CONCEPTS, i + ".ok"))]
        for i in ready:
            if len(running) >= parallel:
                break
            os.makedirs(os.path.join(RAW, i), exist_ok=True)
            fh = open(run_log(i), "a", encoding="utf-8")
            if restarts[i]:
                time.sleep(20)
            running[i] = subprocess.Popen([sys.executable, "-u", os.path.join(ROOT, "tools", "meshy_pipeline.py"), "--env-file", env_file, "run", i],
                                          cwd=ROOT, stdout=fh, stderr=subprocess.STDOUT)
            log("başlatıldı: %s" % i)
        if not running and not ready:
            waiting = [i for i in pending if not os.path.exists(os.path.join(CONCEPTS, i + ".ok"))]
            if not waiting:
                done = [i for i in ids if finished(i)]
                log("bitti: %d/%d tamam; durdurulanlar: %s" % (len(done), len(ids), [i for i in ids if not finished(i)]))
                return
        time.sleep(15)


if __name__ == "__main__":
    main()
