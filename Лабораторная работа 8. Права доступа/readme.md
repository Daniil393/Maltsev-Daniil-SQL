## Таблица cms.articles с учётом Row-Level Security (RLS)

|Role|SELECT|INSERT|UPDATE|DELETE|RLS ограничения|
|:---------|:--------:|---------:|---------|:--------:|--------:|
|admin|✔️|✔️|✔️|✔️|RLS не применим|
|editor|✔️|✔️|✔️ (только свои статьи)|❌|update/check author_id = current_user|
|viewer|✔️ (только опубликованные)|❌|❌|❌|is_published = true|
|reporting_user|✔️ (только опубликованные + ограниченные столбцы)|❌|❌|❌|is_published = true|
