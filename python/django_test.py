# -*- coding:utf-8 -*-
import json

from django.core.serializers.json import Serializer as JsonSerializer
from django.db.models import QuerySet
from django.http import HttpResponse
from django.views import generic

from asset.exceptions import SerializerModelViewError


class ModelJsonView(generic.View):
    model = None
    serializer_class = JsonSerializer

    def __init__(self, **kwargs):
        super(ModelJsonView, self).__init__(**kwargs)
        if not self.model:
            raise SerializerModelViewError(
                '::{}:: Undefined `model` object.'.format(
                    self.__class__.__name__))

    def generate_json_object(self):
        serializer = self.serializer_class()
        queryset = self.queryset()
        if self.has_queryset(queryset):
            return serializer.serialize(queryset=queryset)
        return json.dumps(
            {
                'message': 'not a QuerySet instance',
                'status': 500,
                'method': '<{}::generate_json_object>'.format(
                    self.__class__.__name__),
            })

    @staticmethod
    def has_queryset(queryset):
        return True if isinstance(queryset, QuerySet) else False

    def queryset(self):
        pk = self.kwargs.get('pk', None)
        return self.model.objects.all(
            pk=pk) if pk else self.model.objects.all()

    def get(self, request, *args, **kwargs):
        return HttpResponse(self.generate_json_object(), content_type='json')
