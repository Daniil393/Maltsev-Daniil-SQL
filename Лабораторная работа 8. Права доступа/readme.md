## Таблица cms.articles с учётом Row-Level Security (RLS)

|Role|SELECT|INSERT|UPDATE|DELETE|RLS ограничения|
|:---------|:--------:|:---------:|:---------:|:--------:|:--------:|
|admin|✔️|✔️|✔️|✔️|RLS не применим|
|editor|✔️|✔️|✔️ (только свои статьи)|❌|update/check author_id = current_user|
|viewer|✔️ (только опубликованные)|❌|❌|❌|is_published = true|
|reporting_user|✔️ (только опубликованные + ограниченные столбцы)|❌|❌|❌|is_published = true|


## Таблица cms.comments с учётом RLS

|Role|SELECT|INSERT|UPDATE|DELETE|RLS ограничения|
|:---------|:--------:|:---------:|:---------:|:--------:|:--------:|
|admin|✔️|✔️|✔️|✔️|RLS не применим|
|editor|✔️|✔️ (только user_id = current_user)|❌|❌|писать только от своего имени|
|viewer|✔️|❌|❌|❌|видеть все строки|
|reporting_user|✔️ (ограниченные столбцы)|❌|❌|❌|видеть все строки|
