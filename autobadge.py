import os
import time
import requests

# Configurações do Repositório e Autenticação
TOKEN = "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"
OWNER = "brunnojob"
REPO = "arduino-cloud-telemetry"
BASE_BRANCH = "main"

HEADERS = {
    "Authorization": f"token {TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

API_URL = f"https://api.github.com/repos/{OWNER}/{REPO}"

def get_latest_commit_sha():
    url = f"{API_URL}/git/ref/heads/{BASE_BRANCH}"
    r = requests.get(url, headers=HEADERS)
    return r.json()["object"]["sha"]

def run_automation(total_prs=130):
    print(fazendo_prs := f"A iniciar automação para {total_prs} Pull Requests...")
    
    for i in range(1, total_prs + 1):
        branch_name = f"bot-pr-batch-{i}-{int(time.time())}"
        
        try:
            # 1. Obter o SHA do último commit da main
            base_sha = get_latest_commit_sha()
            
            # 2. Criar uma nova branch
            ref_url = f"{API_URL}/git/refs"
            ref_data = {
                "ref": f"refs/heads/{branch_name}",
                "sha": base_sha
            }
            res = requests.post(ref_url, json=ref_data, headers=HEADERS)
            if res.status_code != 201:
                print(f"[Erro] Falha ao criar branch {branch_name}: {res.text}")
                continue
                
            # 3. Criar ou atualizar um ficheiro de registo (ex: pr-log.txt)
            file_url = f"{API_URL}/contents/pr-log.txt"
            # Verificar se o ficheiro já existe para obter o sha (se necessário)
            file_get = requests.get(file_url, headers=HEADERS)
            file_sha = file_get.json().get("sha") if file_get.status_code == 200 else None
            
            import base64
            content_encoded = base64.b64encode(f"Auto PR iteration {i}\n".encode()).decode()
            
            commit_data = {
                "message": f"chore: auto pr batch {i}",
                "content": content_encoded,
                "branch": branch_name
            }
            if file_sha:
                commit_data["sha"] = file_sha
                
            put_file = requests.put(file_url, json=commit_data, headers=HEADERS)
            if put_file.status_code not in [200, 201]:
                print(f"[Erro] Falha ao atualizar ficheiro no PR {i}: {put_file.text}")
                continue
                
            # 4. Criar o Pull Request
            pr_url = f"{API_URL}/pulls"
            pr_data = {
                "title": f"Automated PR #{i}",
                "head": branch_name,
                "base": BASE_BRANCH,
                "body": f"Batch automation for Pull Shark achievement - item {i}"
            }
            pr_res = requests.post(pr_url, json=pr_data, headers=HEADERS)
            if pr_res.status_code != 201:
                print(f"[Erro] Falha ao criar PR {i}: {pr_res.text}")
                continue
                
            pr_number = pr_res.json()["number"]
            
            # 5. Fazer o Merge do Pull Request imediatamente
            merge_url = f"{API_URL}/pulls/{pr_number}/merge"
            merge_data = {"commit_title": f"Merge pull request #{pr_number} by automation"}
            merge_res = requests.put(merge_url, json=merge_data, headers=HEADERS)
            
            if merge_res.status_code == 200:
                print(f"[Sucesso] PR #{pr_number} criado e fundido com sucesso!")
            else:
                print(f"[Aviso] PR #{pr_number} criado mas falhou o merge: {merge_res.text}")
                
            # Pausa curta para evitar atingir os limites de taxa (rate limits) da API do GitHub
            time.sleep(1.5)
            
        except Exception as e:
            print(f"Ocorreu uma exceção na iteração {i}: {e}")
            time.sleep(3)

if __name__ == "__main__":
    run_automation(130)