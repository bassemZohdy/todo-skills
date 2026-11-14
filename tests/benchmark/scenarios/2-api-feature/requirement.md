Add `GET /items/<id>` to `shop.api.handle`. A known numeric id returns 200 and that item. An unknown id returns 404 with
`{"error": "not found"}`. An id that is not a whole number (for example `/items/abc` or `/items/1.5`) returns 400 with
`{"error": "invalid id"}`. `GET /items` must keep working. Add tests for each case. Run the tests with `python3 -m unittest discover -s tests -t .`.
